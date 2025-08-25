import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_midi/flutter_midi.dart';

class MidiService {
  static final MidiService _instance = MidiService._internal();
  factory MidiService() => _instance;
  MidiService._internal();

  final FlutterMidi _flutterMidi = FlutterMidi();
  bool _isInitialized = false;

  // Cache de notas MIDI
  final Map<String, int> _midiCache = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Desmutar
      await _flutterMidi.unmute();

      // Carregar SoundFont
      final soundfont = await rootBundle.load('assets/sf2/Piano.sf2');
      await _flutterMidi.prepare(sf2: soundfont);

      _isInitialized = true;
      print('MIDI Service inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar MIDI Service: $e');
      throw e;
    }
  }

  int noteToMidi(String note) {
    // Cache para performance
    if (_midiCache.containsKey(note)) {
      return _midiCache[note]!;
    }

    final noteMap = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };

    // Parse da nota (ex: "C#4")
    final match = RegExp(r'([A-G])(#|b)?(\d)').firstMatch(note);
    if (match == null) return 60; // C4 default

    final noteName = match.group(1)!;
    final accidental = match.group(2) ?? '';
    final octave = int.parse(match.group(3)!);

    int midiNumber = (octave + 1) * 12 + noteMap[noteName]!;

    // Ajustar para acidentes
    if (accidental == '#') midiNumber += 1;
    if (accidental == 'b') midiNumber -= 1;

    // Cachear resultado
    _midiCache[note] = midiNumber;

    return midiNumber;
  }

  Future<void> playNote(String note, {int velocity = 127}) async {
    if (!_isInitialized) await initialize();

    final midi = noteToMidi(note);
    await _flutterMidi.playMidiNote(midi: midi, velocity: velocity);
  }

  Future<void> stopNote(String note) async {
    if (!_isInitialized) return;

    final midi = noteToMidi(note);
    await _flutterMidi.stopMidiNote(midi: midi);
  }

  Future<void> playNoteWithDuration(String note, Duration duration,
      {int velocity = 127}) async {
    await playNote(note, velocity: velocity);

    Timer(duration, () {
      stopNote(note);
    });
  }

  Future<void> playMetronomeTick({bool isStrong = false}) async {
    final note = isStrong ? 'A5' : 'E5';
    await playNoteWithDuration(note, const Duration(milliseconds: 50),
        velocity: isStrong ? 127 : 80);
  }

  Future<void> playSequence(
      List<Map<String, dynamic>> sequence, int tempo) async {
    for (final noteData in sequence) {
      final note = noteData['note'] as String;
      final duration = _getDuration(noteData['duration'] as String, tempo);

      await playNoteWithDuration(note, duration);
      await Future.delayed(duration);
    }
  }

  Duration _getDuration(String duration, int tempo) {
    final beatMs = 60000 ~/ tempo; // Milissegundos por batida

    final durations = {
      'whole': beatMs * 4,
      'half': beatMs * 2,
      'quarter': beatMs,
      'eighth': beatMs ~/ 2,
      'sixteenth': beatMs ~/ 4,
    };

    return Duration(milliseconds: durations[duration] ?? beatMs);
  }

  void dispose() {
    _midiCache.clear();
  }
}
