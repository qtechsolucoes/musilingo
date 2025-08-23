// lib/features/solfege/presentation/viewmodel/solfege_exercise_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/features/solfege/data/models/solfege_exercise_model.dart';

// Enum para representar o estado do exercício
enum SolfegeState { idle, countdown, listening, finished }

// Classe para armazenar o resultado de cada nota cantada
class NoteResult {
  final SolfegeNote note;
  final double userPitch; // Frequência que o usuário cantou em Hz
  final bool wasOnTime;

  // Detalhes do erro
  final String? pitchError; // 'acima' ou 'abaixo'
  final String? nameError;
  final String? timingError;

  NoteResult({
    required this.note,
    required this.userPitch,
    required this.wasOnTime,
    this.pitchError,
    this.nameError,
    this.timingError,
  });

  // Verifica se a afinação estava correta (com uma tolerância)
  bool get wasPitchCorrect {
    if (userPitch == 0) return false; // Não cantou
    final targetPitch = note.pitchInHz;
    final tolerance =
        targetPitch * 0.05; // Tolerância de 5% (meio semitom aprox.)
    return (userPitch >= targetPitch - tolerance) &&
        (userPitch <= targetPitch + tolerance);
  }
}

class SolfegeExerciseViewModel extends ChangeNotifier {
  final SolfegeExercise exercise;
  static const Map<String, double> _noteNamesToFrequency = {
    'C': 261.63,
    'C#': 277.18,
    'D': 293.66,
    'D#': 311.13,
    'E': 329.63,
    'F': 349.23,
    'F#': 369.99,
    'G': 392.00,
    'G#': 415.30,
    'A': 440.00,
    'A#': 466.16,
    'B': 493.88,
  };

  SolfegeState _state = SolfegeState.idle;
  int _countdownValue = 0;
  int _currentNoteIndex = -1;
  final List<NoteResult> _results = [];
  String _feedbackMessage = '';

  SolfegeExerciseViewModel({required this.exercise});

  // --- GETTERS ---
  SolfegeState get state => _state;
  int get countdownValue => _countdownValue;
  int get currentNoteIndex => _currentNoteIndex;
  List<NoteResult> get results => _results;
  String get feedbackMessage => _feedbackMessage;

  String get musicXml {
    return _convertExerciseToMusicXml(exercise, _currentNoteIndex, _results);
  }

  // --- LÓGICA DE CONTROLO DO EXERCÍCIO ---
  Future<void> startCountdown() async {
    _state = SolfegeState.countdown;
    final beats = int.parse(exercise.timeSignature.split('/')[0]);
    final tempo = exercise.tempo;
    final beatDuration = Duration(milliseconds: (60000 / tempo).round());

    for (int i = beats; i > 0; i--) {
      _countdownValue = i;
      notifyListeners();
      await Future.delayed(beatDuration);
    }
    _countdownValue = 0;
    _startExercise();
  }

  void _startExercise() {
    _state = SolfegeState.listening;
    _currentNoteIndex = 0;
    _results.clear();
    notifyListeners();
    _startNoteAdvanceEngine();
  }

  // Novo: o motor de jogo que avança as notas no tempo
  Future<void> _startNoteAdvanceEngine() async {
    final tempo = exercise.tempo;
    final beatDuration = Duration(milliseconds: (60000 / tempo).round());

    for (int i = 0; i < exercise.noteSequence.length; i++) {
      _currentNoteIndex = i;
      notifyListeners(); // Notifica para mudar a cor da nota

      final note = exercise.noteSequence[i];
      final durationInBeats = _getDurationInBeats(note.duration);

      await Future.delayed(beatDuration * durationInBeats.round());

      // Simula a avaliação da nota aqui
      // Por enquanto, vamos supor que a nota foi errada se nenhuma voz foi detectada
      if (i == _currentNoteIndex) {
        // Garante que não é uma nota que já foi cantada
        advanceToNextNote(userPitch: 0, wasOnTime: false);
      }
    }
  }

  void processPitch(double pitch) {
    if (_state != SolfegeState.listening || _currentNoteIndex == -1) return;

    // Lógica para comparar o pitch e o nome da nota
    final currentNote = exercise.noteSequence[_currentNoteIndex];
    final targetPitchHz = currentNote.pitchInHz;

    final noteResult = NoteResult(
      note: currentNote,
      userPitch: pitch,
      wasOnTime: true, // Por enquanto, assumimos que sim
    );

    // Se o pitch e o nome estiverem corretos, avança
    if (noteResult.wasPitchCorrect) {
      advanceToNextNote(userPitch: pitch, wasOnTime: true);
    } else {
      // Regista o erro
      advanceToNextNote(userPitch: pitch, wasOnTime: true);
    }
  }

  void advanceToNextNote({required double userPitch, required bool wasOnTime}) {
    if (_currentNoteIndex >= exercise.noteSequence.length) return;

    final currentNote = exercise.noteSequence[_currentNoteIndex];
    final result = NoteResult(
      note: currentNote,
      userPitch: userPitch,
      wasOnTime: wasOnTime,
      // Lógica mais detalhada para determinar o erro
      pitchError: userPitch == 0
          ? null
          : (userPitch > currentNote.pitchInHz ? 'acima' : 'abaixo'),
      nameError: null, // A ser implementado
      timingError: wasOnTime ? null : 'fora de tempo',
    );
    _results.add(result);

    if (_currentNoteIndex < exercise.noteSequence.length - 1) {
      _currentNoteIndex++;
    } else {
      finishExercise();
    }
    notifyListeners();
  }

  void finishExercise() {
    _state = SolfegeState.finished;
    _currentNoteIndex = -1;
    _generateFeedbackMessage();
    notifyListeners();
  }

  void _generateFeedbackMessage() {
    final correctNotes =
        _results.where((r) => r.wasPitchCorrect && r.wasOnTime).length;
    if (correctNotes == _results.length) {
      _feedbackMessage = 'Parabéns! Você acertou todas as notas!';
    } else {
      _feedbackMessage =
          'Você acertou $correctNotes de ${_results.length} notas. Continue a praticar!';
    }
  }

  double _getDurationInBeats(String duration) {
    const durationMap = {
      'whole': 4.0,
      'half': 2.0,
      'quarter': 1.0,
      'eighth': 0.5,
      '16th': 0.25,
      '32nd': 0.125,
    };
    return durationMap[duration] ?? 1.0;
  }

  // --- FUNÇÃO DE CONVERSÃO PARA MUSICXML ---
  String _convertExerciseToMusicXml(
    SolfegeExercise exercise,
    int highlightedNoteIndex,
    List<NoteResult> results,
  ) {
    final timeSignature = exercise.timeSignature;
    final clef = exercise.clef;

    final notesXml = exercise.noteSequence.asMap().entries.map((entry) {
      final index = entry.key;
      final noteData = entry.value;

      String color = AppColors.text.toHex(); // Cor padrão (branca)

      if (index < results.length) {
        final result = results[index];
        color = result.wasPitchCorrect && result.wasOnTime
            ? AppColors.completedHex
            : AppColors.errorHex;
      } else if (index == highlightedNoteIndex) {
        color = AppColors.accent.toHex();
      }

      final pitch =
          noteData.pitch.replaceAll('sharp', '#').replaceAll('flat', 'b');
      final step = pitch.substring(0, 1).toUpperCase();
      final octave = pitch.replaceAll(RegExp(r'[^0-9]'), '');

      String alter = '';
      if (pitch.contains('#')) {
        alter = '<alter>1</alter>';
      } else if (pitch.contains('b')) {
        alter = '<alter>-1</alter>';
      }

      final type = noteData.duration;

      return '''
        <note color="$color">
          <pitch>
            <step>$step</step>
            $alter
            <octave>$octave</octave>
          </pitch>
          <duration>1</duration> 
          <type>$type</type>
        </note>
      ''';
    }).join('');

    return '''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
      <score-partwise version="3.1">
        <part-list>
          <score-part id="P1"><part-name>Music</part-name></score-part>
        </part-list>
        <part id="P1">
          <measure number="1">
            <attributes>
              <divisions>1</divisions>
              <key><fifths>0</fifths></key>
              <time><beats>${timeSignature.split('/')[0]}</beats><beat-type>${timeSignature.split('/')[1]}</beat-type></time>
              <clef><sign>${clef.toLowerCase() == 'treble' ? 'G' : 'F'}</sign><line>${clef.toLowerCase() == 'treble' ? '2' : '4'}</line></clef>
            </attributes>
            $notesXml
          </measure>
        </part>
      </score-partwise>
    ''';
  }
}

// Extensão para converter Color para Hex
extension on Color {
  // ignore: deprecated_member_use
  String toHex() => '#${value.toRadixString(16).substring(2, 8)}';
}
