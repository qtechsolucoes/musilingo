// lib/features/solfege/presentation/viewmodel/solfege_exercise_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/services/sfx_service.dart';
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

  // Adicionamos um getter para verificar se o nome está correto
  bool get wasNameCorrect {
    return nameError == null;
  }
}

class SolfegeExerciseViewModel extends ChangeNotifier {
  final SolfegeExercise exercise;

  SolfegeState _state = SolfegeState.idle;
  int _countdownValue = 0;
  int _currentNoteIndex = -1;
  final List<NoteResult> _results = [];
  String _feedbackMessage = '';
  int _score = 0;
  String _lastRecognizedWord = '';

  SolfegeExerciseViewModel({required this.exercise});

  // --- GETTERS ---
  SolfegeState get state => _state;
  int get countdownValue => _countdownValue;
  int get currentNoteIndex => _currentNoteIndex;
  List<NoteResult> get results => _results;
  String get feedbackMessage => _feedbackMessage;
  int get score => _score;

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
      SfxService.instance.playClick(); // Toca o clique do metrônomo
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

  Future<void> _startNoteAdvanceEngine() async {
    final tempo = exercise.tempo;
    final beatDuration = Duration(milliseconds: (60000 / tempo).round());

    for (int i = 0; i < exercise.noteSequence.length; i++) {
      if (_state != SolfegeState.listening) break;
      _currentNoteIndex = i;
      notifyListeners();

      final note = exercise.noteSequence[i];
      final durationInBeats = getDurationInBeats(note.duration);

      // Toca o metrônomo para cada tempo da nota
      for (int beat = 0; beat < durationInBeats; beat++) {
        if (_state != SolfegeState.listening) break;
        SfxService.instance.playClick();
        await Future.delayed(beatDuration);
      }

      // Se o usuário não cantou a tempo, a nota é marcada como errada
      if (_state == SolfegeState.listening && _results.length == i) {
        advanceToNextNote(userPitch: 0, wasOnTime: false);
      }
    }

    if (_state == SolfegeState.listening) {
      finishExercise();
    }
  }

  void processPitch(double pitch) {
    if (_state != SolfegeState.listening ||
        _currentNoteIndex >= exercise.noteSequence.length ||
        _results.length > _currentNoteIndex) {
      return;
    }

    final currentNote = exercise.noteSequence[_currentNoteIndex];
    final noteResult = NoteResult(
      note: currentNote,
      userPitch: pitch,
      wasOnTime: true,
    );

    if (noteResult.wasPitchCorrect) {
      advanceToNextNote(userPitch: pitch, wasOnTime: true);
    } else {
      advanceToNextNote(userPitch: pitch, wasOnTime: true);
    }
  }

  void processNoteName(String recognizedWords) {
    final words = recognizedWords.split(' ');
    if (words.isNotEmpty) {
      _lastRecognizedWord = words.last;
    }
  }

  void advanceToNextNote({required double userPitch, required bool wasOnTime}) {
    if (_currentNoteIndex >= exercise.noteSequence.length ||
        _results.length > _currentNoteIndex) {
      return;
    }

    final currentNote = exercise.noteSequence[_currentNoteIndex];

    final Map<String, String> noteNameToSyllable = {
      'C': 'Dó',
      'D': 'Ré',
      'E': 'Mi',
      'F': 'Fá',
      'G': 'Sol',
      'A': 'Lá',
      'B': 'Si',
    };

    final expectedSyllable =
        noteNameToSyllable[currentNote.pitch.substring(0, 1).toUpperCase()];
    String? currentNameError;

    if (wasOnTime &&
        expectedSyllable != null &&
        _lastRecognizedWord.toLowerCase() != expectedSyllable.toLowerCase()) {
      currentNameError = 'Nome incorreto';
    }

    final result = NoteResult(
      note: currentNote,
      userPitch: userPitch,
      wasOnTime: wasOnTime,
      pitchError: userPitch == 0
          ? null
          : (userPitch > currentNote.pitchInHz ? 'acima' : 'abaixo'),
      nameError: currentNameError,
      timingError: wasOnTime ? null : 'fora de tempo',
    );
    _results.add(result);

    _lastRecognizedWord = '';

    notifyListeners();
  }

  void finishExercise() {
    if (_state == SolfegeState.finished) return;
    _state = SolfegeState.finished;
    _currentNoteIndex = -1;
    _calculateScore();
    _generateFeedbackMessage();

    final correctNotesCount = _results
        .where((r) => r.wasPitchCorrect && r.wasOnTime && r.wasNameCorrect)
        .length;
    if (correctNotesCount == _results.length && _results.isNotEmpty) {
      SfxService.instance.playCorrectAnswer();
    } else {
      SfxService.instance.playError();
    }

    notifyListeners();
  }

  void _calculateScore() {
    int calculatedScore = 0;
    for (final result in _results) {
      int noteScore = 0;
      if (result.wasPitchCorrect) noteScore += 50;
      if (result.wasNameCorrect) noteScore += 30;
      if (result.wasOnTime) noteScore += 20;

      if (result.wasPitchCorrect && result.wasNameCorrect && result.wasOnTime) {
        noteScore += 50; // Bônus
      }
      calculatedScore += noteScore;
    }
    _score = calculatedScore;
  }

  void _generateFeedbackMessage() {
    final correctNotes = _results
        .where((r) => r.wasPitchCorrect && r.wasOnTime && r.wasNameCorrect)
        .length;
    if (_results.isEmpty) {
      _feedbackMessage = "Nenhuma nota foi avaliada. Tente novamente!";
      return;
    }
    if (correctNotes == _results.length) {
      _feedbackMessage = 'Parabéns! Você acertou todas as notas!';
    } else {
      _feedbackMessage =
          'Você acertou $correctNotes de ${_results.length} notas. Continue a praticar!';
    }
  }

  double getDurationInBeats(String duration) {
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

      String color = AppColors.text.toHex();

      if (index < results.length) {
        final result = results[index];
        color =
            result.wasPitchCorrect && result.wasOnTime && result.wasNameCorrect
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

extension on Color {
  String toHex() {
    // ignore: deprecated_member_use
    return '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}';
  }
}
