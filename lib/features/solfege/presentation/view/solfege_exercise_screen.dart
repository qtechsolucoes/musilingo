// lib/features/solfege/presentation/view/solfege_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/presentation/widgets/time_signature_widget.dart';
import 'package:musilingo/features/solfege/data/models/solfege_exercise_model.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:simple_sheet_music/simple_sheet_music.dart';

// Extension para adicionar a propriedade `beats` ao enum NoteDuration
extension on NoteDuration {
  double get beats {
    switch (this) {
      case NoteDuration.whole:
        return 4.0;
      case NoteDuration.half:
        return 2.0;
      case NoteDuration.quarter:
        return 1.0;
      case NoteDuration.eighth:
        return 0.5;
      case NoteDuration.sixteenth:
        return 0.25;
      case NoteDuration.thirtySecond:
        return 0.125;
      default:
        return 1.0;
    }
  }
}

// Extension para adicionar um método `close` que pode estar faltando na API
extension on MidiPro {
  void close() {}
}

class SolfegeExerciseScreen extends StatefulWidget {
  final SolfegeExercise exercise;

  const SolfegeExerciseScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<SolfegeExerciseScreen> createState() => _SolfegeExerciseScreenState();
}

class _SolfegeExerciseScreenState extends State<SolfegeExerciseScreen> {
  final _midiPro = MidiPro();
  int? _instrumentSoundfontId;
  bool _isSoundfontReady = false;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  @override
  void dispose() {
    _midiPro.close();
    super.dispose();
  }

  // --- FUNÇÕES DE ÁUDIO ---

  Future<void> _initializeAudio() async {
    try {
      const sfPath = 'assets/sf2/GeneralUserGS.sf2';
      final sfId =
          await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);
      if (mounted) {
        setState(() {
          _instrumentSoundfontId = sfId;
          _isSoundfontReady = true;
        });
      }
    } catch (e) {
      debugPrint("Erro ao inicializar o áudio com MidiPro: $e");
    }
  }

  int _noteToMidi(Pitch pitch) {
    final octave = int.parse(pitch.name.substring(pitch.name.length - 1));
    final noteName =
        pitch.name.substring(0, pitch.name.length - 1).toUpperCase();

    const noteValues = {
      'C': 0,
      'CSHARP': 1,
      'D': 2,
      'DSHARP': 3,
      'E': 4,
      'F': 5,
      'FSHARP': 6,
      'G': 7,
      'GSHARP': 8,
      'A': 9,
      'ASHARP': 10,
      'B': 11
    };

    final midiValue = noteValues[noteName] ?? 0;
    return midiValue + (octave + 1) * 12;
  }

  Future<void> _playMelody() async {
    if (!_isSoundfontReady) return;

    final int bpm = widget.exercise.tempo;
    final double beatDurationMs = 60000.0 / bpm;

    for (var noteData in widget.exercise.noteSequence) {
      final noteDuration = _getNoteDuration(noteData.duration);
      final pitch = _getPitch(noteData.pitch);
      final midiNote = _noteToMidi(pitch);

      final durationInMs = (beatDurationMs * noteDuration.beats).round();

      if (midiNote > 0) {
        _midiPro.playNote(
            sfId: _instrumentSoundfontId!,
            channel: 0,
            key: midiNote,
            velocity: 127);

        await Future.delayed(Duration(milliseconds: durationInMs));
        _midiPro.stopNote(
            sfId: _instrumentSoundfontId!, channel: 0, key: midiNote);
      } else {
        await Future.delayed(Duration(milliseconds: durationInMs));
      }
    }
  }

  // --- FUNÇÕES DE CONVERSÃO ---

  ClefType _getClefType(String clefStr) {
    switch (clefStr.toLowerCase()) {
      case 'bass':
        return ClefType.bass;
      case 'treble':
      default:
        return ClefType.treble;
    }
  }

  NoteDuration _getNoteDuration(String durationStr) {
    switch (durationStr.toLowerCase()) {
      case 'whole':
        return NoteDuration.whole;
      case 'half':
        return NoteDuration.half;
      case 'eighth':
        return NoteDuration.eighth;
      case '16th':
        return NoteDuration.sixteenth;
      case '32nd':
        return NoteDuration.thirtySecond;
      case 'quarter':
      default:
        return NoteDuration.quarter;
    }
  }

  Pitch _getPitch(String pitchStr) {
    final formattedPitch = pitchStr.replaceAll('#', 'Sharp').toLowerCase();
    return Pitch.values.firstWhere(
      (p) => p.name == formattedPitch,
      orElse: () => Pitch.c4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clefType = _getClefType(widget.exercise.clef);

    final timeSignatureParts = widget.exercise.timeSignature.split('/');
    final topSignature = int.parse(timeSignatureParts[0]);
    final bottomSignature = int.parse(timeSignatureParts[1]);

    final musicalSymbols = [
      Clef(clefType),
      const KeySignature(KeySignatureType.cMajor),
    ];

    for (var solfegeNote in widget.exercise.noteSequence) {
      musicalSymbols.add(
        Note(
          _getPitch(solfegeNote.pitch),
          noteDuration: _getNoteDuration(solfegeNote.duration),
        ),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.exercise.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // Botão de play para tocar a partitura
            IconButton(
              icon: Icon(Icons.play_arrow,
                  color: _isSoundfontReady ? Colors.white : Colors.white54),
              onPressed: _isSoundfontReady ? _playMelody : null,
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.card.withAlpha(200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SimpleSheetMusic(
                    lineColor: Colors.white.withAlpha(220),
                    measures: [
                      Measure(musicalSymbols),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, top: 28.0),
                    child: TimeSignatureWidget(
                      top: topSignature,
                      bottom: bottomSignature,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
