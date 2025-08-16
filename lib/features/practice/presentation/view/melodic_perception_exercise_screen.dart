// lib/features/practice/presentation/view/melodic_perception_exercise_screen.dart

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/practice/presentation/widgets/melodic_input_panel.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicUtils {
  static const Map<String, int> _noteValues = {
    'C': 0,
    'C#': 1,
    'DB': 1,
    'D': 2,
    'D#': 3,
    'EB': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'GB': 6,
    'G': 7,
    'G#': 8,
    'AB': 8,
    'A': 9,
    'A#': 10,
    'BB': 10,
    'B': 11
  };
  static int noteNameToMidi(String noteName) {
    if (noteName.contains("rest")) return 0;
    final notePart = noteName.replaceAll(RegExp(r'[0-9]'), '');
    final octavePart = noteName.replaceAll(RegExp(r'[^0-9]'), '');

    if (octavePart.isEmpty || !_noteValues.containsKey(notePart)) return 60;

    final octave = int.parse(octavePart);
    return _noteValues[notePart]! + (octave + 1) * 12;
  }

  static const Map<String, double> figureDurations = {
    'whole': 4.0,
    'half': 2.0,
    'quarter': 1.0,
    'eighth': 0.5,
    '16th': 0.25,
    '32nd': 0.125,
    '64th': 0.0625,
  };
}

class MelodicPerceptionExerciseScreen extends StatefulWidget {
  final MelodicExercise exercise;
  const MelodicPerceptionExerciseScreen({super.key, required this.exercise});

  @override
  State<MelodicPerceptionExerciseScreen> createState() =>
      _MelodicPerceptionExerciseScreenState();
}

class _MelodicPerceptionExerciseScreenState
    extends State<MelodicPerceptionExerciseScreen> {
  late final WebViewController _controller;
  final _midiPro = MidiPro();
  int? _instrumentSoundfontId;
  int? _percussionSoundfontId;
  late ConfettiController _confettiController;

  bool _isWebViewReady = false;
  bool _isSoundfontReady = false;

  List<String> _userSequence = [];
  bool _isVerified = false;

  bool _isMetronomeEnabled = true;
  final ValueNotifier<int> _beatCountNotifier = ValueNotifier(0);

  int _octaveOffset = 0;
  AccidentalType _currentAccidental = AccidentalType.none;

  static final Map<String, String> _figureSymbols = {
    'whole': '𝅝',
    'half': '𝅗𝅥',
    'quarter': '𝅘𝅥',
    'eighth': '𝅘𝅥𝅮',
    '16th': '𝅘𝅥𝅯',
    '32nd': '𝅘𝅥𝅰',
    '64th': '𝅘𝅥𝅱',
  };
  static final Map<String, String> _restSymbols = {
    'whole': '𝄻',
    'half': '𝄼',
    'quarter': '𝄽',
    'eighth': '𝄾',
    '16th': '𝄿',
    '32nd': '𝅀',
    '64th': '𝅁',
  };

  late String _selectedNote;
  late String _selectedFigure;

  List<String> get _baseNotePalette {
    final originalPalette = widget.exercise.notePalette;
    if (originalPalette.length < 2) return originalPalette;
    final firstNoteName =
        originalPalette.first.replaceAll(RegExp(r'[0-9]'), '');
    final lastNoteName = originalPalette.last.replaceAll(RegExp(r'[0-9]'), '');
    if (firstNoteName == lastNoteName) {
      return originalPalette.sublist(0, originalPalette.length - 1);
    }
    return originalPalette;
  }

  List<String> get _octaveAdjustedNotePalette {
    return _baseNotePalette.map((note) {
      final noteName = note.substring(0, note.length - 1);
      final octave = int.parse(note.substring(note.length - 1));
      return '$noteName${octave + _octaveOffset}';
    }).toList();
  }

  int get _displayOctave {
    if (_octaveAdjustedNotePalette.isEmpty) return 4 + _octaveOffset;
    final firstNote = _octaveAdjustedNotePalette.first;
    return int.tryParse(firstNote.replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
  }

  void _onOctaveUp() => setState(() {
        if (_octaveOffset < 2) _octaveOffset++;
      });
  void _onOctaveDown() => setState(() {
        if (_octaveOffset > -2) _octaveOffset--;
      });

  void _onAccidentalSelected(AccidentalType type) {
    setState(() {
      _currentAccidental =
          (_currentAccidental == type) ? AccidentalType.none : type;
    });
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _selectedNote = widget.exercise.notePalette.isNotEmpty
        ? widget.exercise.notePalette.first
        : 'C4';
    _selectedFigure = 'quarter';
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await _initializeAudio();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isWebViewReady = true);
            _renderUserSequence();
          },
        ),
      )
      ..loadFlutterAsset('assets/web/index.html');
  }

  Future<void> _initializeAudio() async {
    try {
      const sfPath = 'assets/sf2/GeneralUserGS.sf2';
      final sfInstrument =
          await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);
      final sfPercussion =
          await _midiPro.loadSoundfont(path: sfPath, bank: 128, program: 0);
      if (mounted) {
        setState(() {
          _instrumentSoundfontId = sfInstrument;
          _percussionSoundfontId = sfPercussion;
          _isSoundfontReady = true;
        });
      }
    } catch (e) {
      debugPrint("Erro ao inicializar o áudio com MidiPro: $e");
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _beatCountNotifier.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _playSequence(List<String> sequence) async {
    if (!_isSoundfontReady ||
        _instrumentSoundfontId == null ||
        _percussionSoundfontId == null) {
      return;
    }

    final int bpm = widget.exercise.tempo;
    final double beatDurationMs = 60000.0 / bpm;
    final timeSignatureParts = widget.exercise.timeSignature.split('/');
    final beatsPerMeasure = int.parse(timeSignatureParts[0]);

    for (int i = 0; i < beatsPerMeasure; i++) {
      _beatCountNotifier.value = i + 1;
      _midiPro.playNote(
          sfId: _percussionSoundfontId!,
          channel: 9,
          key: (i == 0) ? 76 : 77,
          velocity: (i == 0) ? 127 : 100);
      await Future.delayed(Duration(milliseconds: beatDurationMs.round()));
    }

    int currentBeat = 0;
    for (String noteData in sequence) {
      final parts = noteData.split('_');
      final noteName = parts[0];
      final durationName = parts[1];
      final midiNote = MusicUtils.noteNameToMidi(noteName);
      final beatDurationMultiplier =
          MusicUtils.figureDurations[durationName] ?? 1.0;

      if (_isMetronomeEnabled) {
        _beatCountNotifier.value = (currentBeat % beatsPerMeasure) + 1;
        _midiPro.playNote(
            sfId: _percussionSoundfontId!,
            channel: 9,
            key: (currentBeat % beatsPerMeasure == 0) ? 76 : 77,
            velocity: 100);
      }
      if (!noteName.contains("rest")) {
        _midiPro.playNote(
            sfId: _instrumentSoundfontId!,
            channel: 0,
            key: midiNote,
            velocity: 127);
      }

      await Future.delayed(Duration(milliseconds: beatDurationMs.round()));

      for (int i = 1; i < beatDurationMultiplier; i++) {
        if (_isMetronomeEnabled) {
          _beatCountNotifier.value = ((currentBeat + i) % beatsPerMeasure) + 1;
          _midiPro.playNote(
              sfId: _percussionSoundfontId!,
              channel: 9,
              key: ((currentBeat + i) % beatsPerMeasure == 0) ? 76 : 77,
              velocity: 100);
        }
        await Future.delayed(Duration(milliseconds: beatDurationMs.round()));
      }

      if (!noteName.contains("rest")) {
        _midiPro.stopNote(
            sfId: _instrumentSoundfontId!, channel: 0, key: midiNote);
      }
      currentBeat += beatDurationMultiplier.round();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _beatCountNotifier.value = 0;
  }

  void _playExerciseMelody() => _playSequence(widget.exercise.correctSequence);
  void _playUserSequence() => _playSequence(_userSequence);

  void _addRest() {
    if (_isVerified) return;
    setState(() => _userSequence.add("rest_$_selectedFigure"));
    _renderUserSequence();
  }

  void _addNoteToSequence() {
    if (_isVerified) return;
    String noteNameOnly = _selectedNote.replaceAll(RegExp(r'[0-9]'), '');
    String accidentalSign = "";
    if (_currentAccidental == AccidentalType.sharp) {
      accidentalSign = "#";
    } else if (_currentAccidental == AccidentalType.flat) {
      accidentalSign = "b";
    }
    final finalNoteName = '$noteNameOnly$accidentalSign$_displayOctave';
    setState(() {
      _userSequence.add("${finalNoteName}_$_selectedFigure");
      _currentAccidental = AccidentalType.none;
    });
    _renderUserSequence();
  }

  void _removeLastNote() {
    if (_isVerified || _userSequence.isEmpty) return;
    setState(() => _userSequence.removeLast());
    _renderUserSequence();
  }

  void _renderUserSequence(
      {String Function(String note, bool isCorrect)? colorizer}) {
    if (!_isWebViewReady) return;
    final timeSignatureParts = widget.exercise.timeSignature.split('/');
    final beatsPerMeasure = double.parse(timeSignatureParts[0]);
    final beatType = double.parse(timeSignatureParts[1]);
    final measureCapacity = beatsPerMeasure * (4.0 / beatType);
    StringBuffer measuresXml = StringBuffer();
    int measureCount = 1;
    double currentMeasureDuration = 0.0;
    measuresXml.write('<measure number="$measureCount">');
    measuresXml.write(
        '<attributes><divisions>4</divisions><key><fifths>0</fifths></key><time><beats>${beatsPerMeasure.toInt()}</beats><beat-type>${beatType.toInt()}</beat-type></time><clef><sign>${widget.exercise.clef == 'treble' ? 'G' : 'F'}</sign><line>${widget.exercise.clef == 'treble' ? '2' : '4'}</line></clef></attributes>');
    for (var entry in _userSequence.asMap().entries) {
      final index = entry.key;
      final noteData = entry.value.split('_');
      final noteName = noteData[0];
      final figure = noteData[1];
      final noteDuration =
          (MusicUtils.figureDurations[figure] ?? 0.0) * (4.0 / beatType);
      if (currentMeasureDuration + noteDuration > measureCapacity + 0.001) {
        measuresXml.write('</measure>');
        measureCount++;
        measuresXml.write('<measure number="$measureCount">');
        currentMeasureDuration = 0;
      }
      currentMeasureDuration += noteDuration;
      String colorTag = "";
      if (colorizer != null) {
        final isCorrect = index < widget.exercise.correctSequence.length &&
            widget.exercise.correctSequence[index] == entry.value;
        colorTag = colorizer(entry.value, isCorrect);
      }
      final type = figure;
      final xmlDuration = (MusicUtils.figureDurations[figure]! * 4).toInt();
      if (noteName.contains("rest")) {
        measuresXml.write(
            '<note $colorTag><rest/><duration>$xmlDuration</duration><type>$type</type></note>');
      } else {
        String step = noteName.substring(0, 1);
        final octave = noteName.substring(noteName.length - 1);
        String alter = "0";
        String accidental = "";
        if (noteName.contains("#")) {
          alter = "1";
          accidental = "<accidental>sharp</accidental>";
        } else if (noteName.contains("b")) {
          alter = "-1";
          accidental = "<accidental>flat</accidental>";
        }
        measuresXml.write(
            """<note $colorTag><pitch><step>$step</step><alter>$alter</alter><octave>$octave</octave></pitch><duration>$xmlDuration</duration><type>$type</type>$accidental</note>""");
      }
    }
    measuresXml.write(
        '<barline location="right"><bar-style>light-heavy</bar-style></barline>');
    measuresXml.write('</measure>');
    final fullXml =
        """<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd"><score-partwise><part-list><score-part id="P1"><part-name>Music</part-name></score-part></part-list><part id="P1">${measuresXml.toString()}</part></score-partwise>""";
    _loadScoreIntoWebView(fullXml);
  }

  void _verifyAnswer() {
    setState(() => _isVerified = true);
    final bool isCorrect = const ListEquality()
        .equals(_userSequence, widget.exercise.correctSequence);
    final userSession = context.read<UserSession>();
    _renderUserSequence(
        colorizer: (note, isCorrect) =>
            'color="${isCorrect ? AppColors.completedHex : AppColors.errorHex}"');
    if (isCorrect) {
      userSession.answerCorrectly();
      userSession.recordPractice();
      _showSuccessDialog();
    } else {
      userSession.answerWrongly();
      _showErrorDialog();
    }
  }

  void _loadScoreIntoWebView(String musicXml) {
    if (_isWebViewReady) {
      final escapedXml = musicXml
          .replaceAll('\\', '\\\\')
          .replaceAll("`", "\\`")
          .replaceAll("\n", "")
          .replaceAll("\r", "");
      _controller.runJavaScript('window.loadScore(`$escapedXml`)');
    }
  }

  Future<void> _showSuccessDialog() {
    _confettiController.play();
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                backgroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Excelente!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.bold)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star, color: AppColors.accent, size: 50),
                  const SizedBox(height: 12),
                  const Text('Você transcreveu a melodia perfeitamente!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('+10 pontos!',
                      style: TextStyle(
                          color: AppColors.textSecondary
                              .withAlpha((255 * 0.8).round())))
                ]),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.completed),
                      child: const Text('Continuar'))
                ]));
  }

  Future<void> _showErrorDialog() {
    final livesLeft = context.read<UserSession>().currentUser?.lives ?? 0;
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                backgroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied,
                          color: AppColors.error, size: 24),
                      SizedBox(width: 8),
                      Text('Quase lá!', style: TextStyle(color: Colors.white))
                    ]),
                content: Text(
                    'A sequência não está correta.\nVidas restantes: $livesLeft',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _userSequence = [];
                          _isVerified = false;
                          _octaveOffset = 0;
                          _currentAccidental = AccidentalType.none;
                          _selectedNote = widget.exercise.notePalette.isNotEmpty
                              ? widget.exercise.notePalette.first
                              : 'C4';
                          _selectedFigure = 'quarter';
                        });
                        _renderUserSequence();
                      },
                      child: const Text('Tentar Novamente'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWebViewReady || !_isSoundfontReady) {
      return Scaffold(
          appBar: AppBar(
              title: Text(widget.exercise.title),
              backgroundColor: AppColors.background),
          body: const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text("Carregando exercício...")
              ])));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
              icon: const Icon(Icons.undo),
              tooltip: "Desfazer última nota",
              onPressed: _isVerified ? null : _removeLastNote),
          IconButton(
            icon: SvgPicture.asset('assets/images/metronome.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                    _isMetronomeEnabled ? AppColors.accent : Colors.white54,
                    BlendMode.srcIn)),
            tooltip: "Metrônomo",
            onPressed: () =>
                setState(() => _isMetronomeEnabled = !_isMetronomeEnabled),
          ),
          IconButton(
              icon: const Icon(Icons.hearing),
              tooltip: "Ouvir o desafio",
              onPressed: _isVerified ? null : _playExerciseMelody),
          IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: "Ouvir sua resposta",
              onPressed: _isVerified ? null : _playUserSequence),
          if (_isVerified)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Tentar Novamente",
              onPressed: () {
                setState(() {
                  _userSequence = [];
                  _isVerified = false;
                  _octaveOffset = 0;
                  _currentAccidental = AccidentalType.none;
                  _selectedNote = widget.exercise.notePalette.isNotEmpty
                      ? widget.exercise.notePalette.first
                      : 'C4';
                  _selectedFigure = 'quarter';
                });
                _renderUserSequence();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    // --- MUDANÇA DE PADDING APLICADA AQUI ---
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.background,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: WebViewWidget(controller: _controller),
                      ),
                    ),
                  ),
                ),
                MelodicInputPanel(
                  notePalette: _octaveAdjustedNotePalette,
                  figurePalette: _figureSymbols,
                  restPalette: _restSymbols,
                  selectedNote: _selectedNote,
                  selectedFigure: _selectedFigure,
                  isVerified: _isVerified,
                  onNoteSelected: (note) => setState(() =>
                      _selectedNote = note.replaceAll(RegExp(r'[0-9]'), '')),
                  onFigureSelected: (figure) =>
                      setState(() => _selectedFigure = figure),
                  onAddNote: _addNoteToSequence,
                  onAddRest: _addRest,
                  onVerify: _verifyAnswer,
                  displayOctave: _displayOctave,
                  onOctaveUp: _onOctaveUp,
                  onOctaveDown: _onOctaveDown,
                  currentAccidental: _currentAccidental,
                  onAccidentalSelected: _onAccidentalSelected,
                ),
              ],
            ),
            Positioned(
              top: 24,
              left: 24,
              child: ValueListenableBuilder<int>(
                valueListenable: _beatCountNotifier,
                builder: (context, beat, child) {
                  return AnimatedOpacity(
                    opacity: beat == 0 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(200),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.accent.withAlpha((255 * 0.7).round()),
                            blurRadius: 15.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(beat.toString(),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
