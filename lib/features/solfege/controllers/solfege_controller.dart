import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_midi/flutter_midi.dart';
import '../models/solfege_exercise.dart';
import '../services/audio_analysis_service.dart';
import '../services/osmd_service.dart';

enum SolfegeState { idle, preparing, playing, listening, analyzing, finished }

class SolfegeController extends ChangeNotifier {
  final AudioAnalysisService _audioService = AudioAnalysisService();
  final OSMDService _osmdService = OSMDService();
  final FlutterMidi _flutterMidi = FlutterMidi();

  SolfegeExercise? _currentExercise;
  SolfegeState _state = SolfegeState.idle;
  int _currentNoteIndex = 0;
  int _countdownValue = 4;
  Timer? _metronomeTimer;
  StreamSubscription? _audioAnalysisSubscription;

  final List<NoteResult> _noteResults = [];
  double _currentScore = 0;

  // Getters
  SolfegeExercise? get currentExercise => _currentExercise;
  SolfegeState get state => _state;
  int get currentNoteIndex => _currentNoteIndex;
  int get countdownValue => _countdownValue;
  double get currentScore => _currentScore;
  List<NoteResult> get noteResults => _noteResults;

  Future<void> initialize() async {
    try {
      // Inicializar serviços
      await _audioService.initialize();
      await _osmdService.initialize();

      // Preparar MIDI
      await _flutterMidi.unmute();
      final soundfont = await rootBundle.load('assets/sf2/Piano.sf2');
      await _flutterMidi.prepare(sf2: soundfont);

      notifyListeners();
    } catch (e) {
      print('Erro na inicialização: $e');
      throw e;
    }
  }

  Future<void> loadExercise(SolfegeExercise exercise) async {
    _currentExercise = exercise;
    _currentNoteIndex = 0;
    _noteResults.clear();
    _state = SolfegeState.idle;

    await _osmdService.loadExercise(exercise);
    notifyListeners();
  }

  Future<void> playExercise() async {
    if (_currentExercise == null) return;

    _state = SolfegeState.playing;
    notifyListeners();

    // Tocar cada nota
    for (int i = 0; i < _currentExercise!.noteSequence.length; i++) {
      final note = _currentExercise!.noteSequence[i];

      // Destacar nota atual
      await _osmdService.highlightNote(i, 'active');

      // Tocar nota MIDI
      await _playMidiNote(note);

      // Aguardar duração da nota
      await Future.delayed(
        Duration(
            milliseconds:
                (note.getDurationInSeconds(_currentExercise!.tempo) * 1000)
                    .round()),
      );

      // Remover destaque
      await _osmdService.highlightNote(i, 'neutral');
    }

    _state = SolfegeState.idle;
    notifyListeners();
  }

  Future<void> _playMidiNote(NoteInfo note) async {
    final midiNumber = _noteToMidiNumber(note.note);
    await _flutterMidi.playMidiNote(midi: midiNumber);

    // Parar nota após duração
    Timer(
      Duration(
          milliseconds:
              (note.getDurationInSeconds(_currentExercise!.tempo) * 900)
                  .round()),
      () => _flutterMidi.stopMidiNote(midi: midiNumber),
    );
  }

  int _noteToMidiNumber(String note) {
    final noteMap = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };

    final match = RegExp(r'([A-G])(#?)(\d)').firstMatch(note);
    if (match == null) return 60; // C4 default

    final noteName = match.group(1)!;
    final sharp = match.group(2) == '#' ? 1 : 0;
    final octave = int.parse(match.group(3)!);

    return (octave + 1) * 12 + noteMap[noteName]! + sharp;
  }

  Future<void> startSolfege() async {
    if (_currentExercise == null) return;

    _state = SolfegeState.preparing;
    _countdownValue = 4;
    notifyListeners();

    // Countdown com metrônomo
    await _startMetronomeCountdown();

    // Iniciar gravação e análise
    _state = SolfegeState.listening;
    _currentNoteIndex = 0;
    notifyListeners();

    // Começar análise de áudio
    _audioAnalysisSubscription?.cancel();
    _audioAnalysisSubscription = _audioService.startAnalysis().listen(
          (analysisData) => _processAudioAnalysis(analysisData),
        );

    // Processar cada nota
    await _processNotes();
  }

  Future<void> _startMetronomeCountdown() async {
    final tempo = _currentExercise!.tempo;
    final beatDuration = Duration(milliseconds: (60000 / tempo).round());

    for (int i = 4; i > 0; i--) {
      _countdownValue = i;
      notifyListeners();

      // Tocar som do metrônomo
      await _playMetronomeTick(i == 1);

      await Future.delayed(beatDuration);
    }
  }

  Future<void> _playMetronomeTick(bool isLastTick) async {
    final midiNote = isLastTick ? 81 : 76; // A5 para último, E5 para outros
    await _flutterMidi.playMidiNote(midi: midiNote);

    Timer(const Duration(milliseconds: 50), () {
      _flutterMidi.stopMidiNote(midi: midiNote);
    });
  }

  Future<void> _processNotes() async {
    for (int i = 0; i < _currentExercise!.noteSequence.length; i++) {
      _currentNoteIndex = i;
      final note = _currentExercise!.noteSequence[i];

      // Destacar nota atual
      await _osmdService.highlightNote(i, 'active');

      // Resetar timer para nova nota
      _audioService.resetNoteTimer();

      // Variáveis para análise
      double? detectedFrequency;
      String? detectedWord;
      double? detectedDuration;

      // Aguardar duração da nota com análise
      final noteDuration = note.getDurationInSeconds(_currentExercise!.tempo);
      final startTime = DateTime.now();

      // Coletar dados durante a duração da nota
      final List<double> frequencies = [];
      final List<String> words = [];

      while (DateTime.now().difference(startTime).inMilliseconds <
          noteDuration * 1000) {
        await Future.delayed(const Duration(milliseconds: 50));

        // Coletar dados atuais (assumindo que estão disponíveis via stream)
        // Este é um placeholder - os dados reais viriam do stream
      }

      detectedDuration =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;

      // Análise dos resultados
      final pitchCorrect = detectedFrequency != null &&
          _audioService.checkPitch(note.frequency, detectedFrequency);

      final durationCorrect = detectedDuration != null &&
          _audioService.checkDuration(noteDuration, detectedDuration);

      final nameCorrect = detectedWord != null &&
          _audioService.checkNoteName(note.lyric, detectedWord);

      // Salvar resultado
      _noteResults.add(NoteResult(
        note: note.note,
        expectedName: note.lyric,
        detectedName: detectedWord,
        expectedFrequency: note.frequency,
        detectedFrequency: detectedFrequency,
        expectedDuration: noteDuration,
        detectedDuration: detectedDuration,
        pitchCorrect: pitchCorrect ?? false,
        durationCorrect: durationCorrect ?? false,
        nameCorrect: nameCorrect ?? false,
      ));

      // Atualizar visual
      final isCorrect = (pitchCorrect ?? false) &&
          (durationCorrect ?? false) &&
          (nameCorrect ?? false);

      await _osmdService.highlightNote(i, isCorrect ? 'correct' : 'incorrect');

      notifyListeners();
    }

    // Finalizar
    await _finishExercise();
  }

  AudioAnalysisData? _lastAnalysisData;
  final List<double> _frequencyBuffer = [];
  final List<String> _wordBuffer = [];

  void _processAudioAnalysis(AudioAnalysisData data) {
    _lastAnalysisData = data;

    // Adicionar aos buffers
    if (data.frequency > 0) {
      _frequencyBuffer.add(data.frequency);
      if (_frequencyBuffer.length > 20) {
        _frequencyBuffer.removeAt(0);
      }
    }

    if (data.detectedWord.isNotEmpty) {
      _wordBuffer.add(data.detectedWord);
    }
  }

  Future<void> _finishExercise() async {
    _state = SolfegeState.analyzing;
    notifyListeners();

    // Parar gravação
    await _audioService.stopAnalysis();
    _audioAnalysisSubscription?.cancel();

    // Calcular pontuação
    _calculateScore();

    _state = SolfegeState.finished;
    notifyListeners();
  }

  void _calculateScore() {
    if (_noteResults.isEmpty) {
      _currentScore = 0;
      return;
    }

    int correctPitch = 0;
    int correctDuration = 0;
    int correctName = 0;

    for (final result in _noteResults) {
      if (result.pitchCorrect) correctPitch++;
      if (result.durationCorrect) correctDuration++;
      if (result.nameCorrect) correctName++;
    }

    final totalNotes = _noteResults.length;
    final totalCorrect = _noteResults
        .where((r) => r.pitchCorrect && r.durationCorrect && r.nameCorrect)
        .length;

    // Calcular porcentagem geral
    final accuracy = totalCorrect / totalNotes;

    // Sistema de pontuação
    if (accuracy == 1.0) {
      _currentScore = 100;
    } else if (accuracy >= 0.5) {
      _currentScore = accuracy * 80; // 50% = 40 pontos, 99% = 79 pontos
    } else {
      _currentScore = -(50 - accuracy * 100); // Abaixo de 50% perde pontos
    }

    notifyListeners();
  }

  SolfegeResult getResults() {
    final totalNotes = _noteResults.length;

    int correctPitch = 0;
    int correctDuration = 0;
    int correctName = 0;

    for (final result in _noteResults) {
      if (result.pitchCorrect) correctPitch++;
      if (result.durationCorrect) correctDuration++;
      if (result.nameCorrect) correctName++;
    }

    final totalCorrect = _noteResults
        .where((r) => r.pitchCorrect && r.durationCorrect && r.nameCorrect)
        .length;

    return SolfegeResult(
      totalNotes: totalNotes,
      correctPitch: correctPitch,
      correctDuration: correctDuration,
      correctName: correctName,
      overallAccuracy: totalNotes > 0 ? totalCorrect / totalNotes : 0,
      score: _currentScore.round(),
      noteResults: _noteResults,
    );
  }

  void reset() {
    _state = SolfegeState.idle;
    _currentNoteIndex = 0;
    _noteResults.clear();
    _currentScore = 0;
    _osmdService.resetHighlights();
    notifyListeners();
  }

  @override
  void dispose() {
    _metronomeTimer?.cancel();
    _audioAnalysisSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
