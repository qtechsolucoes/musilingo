import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/solfege_exercise.dart';
import '../services/audio_analysis_service.dart';
import '../services/gamification_service.dart';
import '../services/calibration_service.dart';

class SolfegeProvider extends ChangeNotifier {
  final AudioAnalysisService _audioService = AudioAnalysisService();
  final GamificationService _gamificationService = GamificationService();
  final CalibrationService _calibrationService = CalibrationService();

  // Streams
  final BehaviorSubject<SolfegeState> _stateStream =
      BehaviorSubject<SolfegeState>.seeded(SolfegeState.idle);

  final BehaviorSubject<double> _progressStream =
      BehaviorSubject<double>.seeded(0.0);

  final BehaviorSubject<AudioAnalysisData?> _audioDataStream =
      BehaviorSubject<AudioAnalysisData?>.seeded(null);

  // Estado
  SolfegeExercise? _currentExercise;
  List<NoteResult> _noteResults = [];
  UserStats? _userStats;
  List<Achievement> _unlockedAchievements = [];

  // Getters
  Stream<SolfegeState> get stateStream => _stateStream.stream;
  Stream<double> get progressStream => _progressStream.stream;
  Stream<AudioAnalysisData?> get audioDataStream => _audioDataStream.stream;

  SolfegeExercise? get currentExercise => _currentExercise;
  List<NoteResult> get noteResults => _noteResults;
  UserStats? get userStats => _userStats;
  List<Achievement> get unlockedAchievements => _unlockedAchievements;

  SolfegeProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _calibrationService.loadCalibration();
      await _audioService.initialize();
      await _loadUserStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro na inicialização do provider: $e');
    }
  }

  Future<void> _loadUserStats() async {
    try {
      _userStats = await _gamificationService.getUserStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
    }
  }

  void setExercise(SolfegeExercise exercise) {
    _currentExercise = exercise;
    _noteResults.clear();
    _stateStream.add(SolfegeState.idle);
    notifyListeners();
  }

  Future<void> startAnalysis() async {
    if (_currentExercise == null) return;

    _stateStream.add(SolfegeState.preparing);

    // Countdown
    for (int i = 4; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      _progressStream.add(i / 4);
    }

    _stateStream.add(SolfegeState.listening);
    _progressStream.add(0.0);

    // Iniciar análise de áudio
    _audioService.startAnalysis().listen(
      (data) {
        _audioDataStream.add(data);
        _processAudioData(data);
      },
      onError: (error) {
        debugPrint('Erro na análise de áudio: $error');
        _stateStream.add(SolfegeState.error);
      },
    );
  }

  void _processAudioData(AudioAnalysisData data) {
    if (_currentExercise == null) return;

    final currentNoteIndex = _noteResults.length;
    if (currentNoteIndex >= _currentExercise!.noteSequence.length) {
      _finishAnalysis();
      return;
    }

    final currentNote = _currentExercise!.noteSequence[currentNoteIndex];
    final expectedFrequency = currentNote.frequency;
    final expectedDuration =
        currentNote.getDurationInSeconds(_currentExercise!.tempo);

    // Verificar pitch
    final pitchCorrect = (data.frequency - expectedFrequency).abs() <=
        _calibrationService.pitchTolerance;

    // Verificar duração
    final durationCorrect = (data.currentDuration - expectedDuration).abs() <=
        _calibrationService.durationTolerance;

    // Verificar nome
    final nameCorrect = data.detectedWord
        .toLowerCase()
        .contains(currentNote.lyric.toLowerCase());

    // Se a nota atual foi completada
    if (data.currentDuration >= expectedDuration) {
      _noteResults.add(NoteResult(
        note: currentNote.note,
        expectedName: currentNote.lyric,
        detectedName: data.detectedWord,
        expectedFrequency: expectedFrequency,
        detectedFrequency: data.frequency,
        expectedDuration: expectedDuration,
        detectedDuration: data.currentDuration,
        pitchCorrect: pitchCorrect,
        durationCorrect: durationCorrect,
        nameCorrect: nameCorrect,
      ));

      // Atualizar progresso
      _progressStream
          .add((_noteResults.length / _currentExercise!.noteSequence.length));

      // Resetar timer para próxima nota
      _audioService.resetNoteTimer();
    }
  }

  Future<void> _finishAnalysis() async {
    _stateStream.add(SolfegeState.analyzing);
    await _audioService.stopAnalysis();

    // Calcular resultados
    final result = _calculateResult();

    // Salvar no banco
    await _gamificationService.saveExerciseResult(
      _currentExercise!.id,
      result,
      _currentExercise!.difficultyLevel,
    );

    // Recarregar estatísticas
    await _loadUserStats();

    // Ajustar tolerâncias baseado no desempenho
    _calibrationService.adjustTolerances(result.overallAccuracy);

    _stateStream.add(SolfegeState.finished);
    notifyListeners();
  }

  SolfegeResult _calculateResult() {
    int correctPitch = 0;
    int correctDuration = 0;
    int correctName = 0;

    for (final result in _noteResults) {
      if (result.pitchCorrect) correctPitch++;
      if (result.durationCorrect) correctDuration++;
      if (result.nameCorrect) correctName++;
    }

    final totalNotes = _currentExercise!.noteSequence.length;
    final totalCorrect = _noteResults
        .where((r) => r.pitchCorrect && r.durationCorrect && r.nameCorrect)
        .length;

    final accuracy = totalNotes > 0 ? totalCorrect / totalNotes : 0.0;

    // Calcular pontuação
    int score;
    if (accuracy == 1.0) {
      score = 100;
    } else if (accuracy >= 0.5) {
      score = (accuracy * 80).round();
    } else {
      score = -(50 - (accuracy * 100).round());
    }

    return SolfegeResult(
      totalNotes: totalNotes,
      correctPitch: correctPitch,
      correctDuration: correctDuration,
      correctName: correctName,
      overallAccuracy: accuracy,
      score: score,
      noteResults: _noteResults,
    );
  }

  void reset() {
    _noteResults.clear();
    _stateStream.add(SolfegeState.idle);
    _progressStream.add(0.0);
    _audioDataStream.add(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _stateStream.close();
    _progressStream.close();
    _audioDataStream.close();
    _audioService.dispose();
    super.dispose();
  }
}

enum SolfegeState {
  idle,
  preparing,
  playing,
  listening,
  analyzing,
  finished,
  error,
}
