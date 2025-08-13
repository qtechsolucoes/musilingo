// lib/features/practice/presentation/view/melodic_perception_exercise_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
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
    if (noteName.length < 2) return 60;
    try {
      final octave = int.parse(noteName.substring(noteName.length - 1));
      final key = noteName.substring(0, noteName.length - 1).toUpperCase();
      if (!_noteValues.containsKey(key)) return 60;
      return _noteValues[key]! + (octave + 1) * 12;
    } catch (e) {
      return 60;
    }
  }

  static const Map<String, double> figureDurations = {
    'whole': 4.0,
    'half': 2.0,
    'quarter': 1.0,
    'eighth': 0.5,
    '16th': 0.25,
    '32nd': 0.125,
    '64th': 0.0625
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

  bool _isMetronomeEnabled = false;
  final ValueNotifier<int> _beatCountNotifier = ValueNotifier(0);
  Timer? _playbackTimer;

  static const Map<String, String> _allFigureNames = {
    'whole': 'Semibreve (𝅝)',
    'half': 'Mínima (𝅗𝅥)',
    'quarter': 'Semínima (♩)',
    'eighth': 'Colcheia (♪)',
    '16th': 'Semicolcheia (♬)',
  };

  late String _selectedNote;
  late String _selectedFigure;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _selectedNote = widget.exercise.notePalette.isNotEmpty
        ? widget.exercise.notePalette.first
        : 'C4';
    _selectedFigure = widget.exercise.figurePalette.isNotEmpty
        ? widget.exercise.figurePalette.first
        : 'quarter';

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
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isWebViewReady = true;
              });
              _renderUserSequence();
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/web/index.html');
  }

  Future<void> _initializeAudio() async {
    try {
      final sfInstrument = await _midiPro.loadSoundfont(
        path: 'assets/sf2/GeneralUserGS.sf2',
        bank: 0,
        program: 0,
      );
      final sfPercussion = await _midiPro.loadSoundfont(
        path: 'assets/sf2/Standard_Drum_Kit.sf2',
        bank: 0,
        program: 0,
      );
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
    _playbackTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  Future<void> _playExerciseMelody() async {
    if (!_isSoundfontReady ||
        _instrumentSoundfontId == null ||
        _percussionSoundfontId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instrumentos ainda não estão prontos.')),
      );
      return;
    }

    _playbackTimer?.cancel();

    final int bpm = widget.exercise.tempo;
    final double beatDurationMs = 60000.0 / bpm;
    const int metronomeMidiNote = 37;
    const int percussionChannel = 9;

    Map<int, List<Function>> events = {};
    int totalDurationMs = 0;
    final timeSignatureParts = widget.exercise.timeSignature.split('/');
    final beatsPerMeasure = int.parse(timeSignatureParts[0]);

    double melodyDuration = 0;
    for (String noteData in widget.exercise.correctSequence) {
      final durationName = noteData.split('_')[1];
      final durationMultiplier =
          MusicUtils.figureDurations[durationName] ?? 1.0;
      melodyDuration += beatDurationMs * durationMultiplier;
    }
    final totalBeats =
        (melodyDuration / beatDurationMs).ceil() + beatsPerMeasure;

    if (_isMetronomeEnabled) {
      for (int i = 0; i < totalBeats; i++) {
        final time = (i * beatDurationMs).round();
        events.putIfAbsent(time, () => []).add(() {
          _beatCountNotifier.value = (i % beatsPerMeasure) + 1;
          _midiPro.playNote(
              sfId: _percussionSoundfontId!,
              channel: percussionChannel,
              key: metronomeMidiNote,
              velocity: (i % beatsPerMeasure) == 0 ? 127 : 100);
        });
      }
    }

    double currentTimeMs =
        _isMetronomeEnabled ? (beatsPerMeasure * beatDurationMs) : 0;
    for (String noteData in widget.exercise.correctSequence) {
      final parts = noteData.split('_');
      final noteName = parts[0];
      final durationName = parts[1];
      final midiNote = MusicUtils.noteNameToMidi(noteName);
      final durationMultiplier =
          MusicUtils.figureDurations[durationName] ?? 1.0;
      final noteDuration = (beatDurationMs * durationMultiplier);
      final noteOnTime = currentTimeMs.round();
      final noteOffTime = (currentTimeMs + noteDuration - 50).round();

      events.putIfAbsent(noteOnTime, () => []).add(() {
        _midiPro.playNote(
            sfId: _instrumentSoundfontId!,
            channel: 0,
            key: midiNote,
            velocity: 127);
      });
      events.putIfAbsent(noteOffTime, () => []).add(() {
        _midiPro.stopNote(
            sfId: _instrumentSoundfontId!, channel: 0, key: midiNote);
      });
      currentTimeMs += noteDuration;
    }
    totalDurationMs = max(totalDurationMs, currentTimeMs.round());

    final startTime = DateTime.now();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      final timesToExecute = events.keys
          .where((time) => time >= elapsed && time < elapsed + 10)
          .toList();
      for (var time in timesToExecute) {
        events[time]?.forEach((action) => action());
        events.remove(time);
      }

      if (elapsed > totalDurationMs + 500) {
        timer.cancel();
        _beatCountNotifier.value = 0;
      }
    });
  }

  // MÉTODOS RESTAURADOS
  void _addNoteToSequence() {
    if (_isVerified) return;
    final timeSignatureParts = widget.exercise.timeSignature.split('/');
    final beatsPerMeasure = int.parse(timeSignatureParts[0]);
    final beatType = int.parse(timeSignatureParts[1]);
    final measureCapacity = beatsPerMeasure * (4.0 / beatType);
    double currentMeasureDuration = 0;
    for (var noteData in _userSequence) {
      final duration = MusicUtils.figureDurations[noteData.split('_')[1]] ?? 0;
      currentMeasureDuration += duration;
      if (currentMeasureDuration >= measureCapacity) {
        currentMeasureDuration -= measureCapacity;
      }
    }
    final newNoteDuration = MusicUtils.figureDurations[_selectedFigure] ?? 0;
    if (currentMeasureDuration + newNoteDuration > measureCapacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A figura não cabe neste compasso!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _userSequence.add("${_selectedNote}_$_selectedFigure");
    });
    _renderUserSequence();
  }

  void _removeLastNote() {
    if (_isVerified || _userSequence.isEmpty) return;
    setState(() {
      _userSequence.removeLast();
    });
    _renderUserSequence();
  }

  void _renderUserSequence({
    String Function(String note, bool isCorrect)? colorizer,
  }) {
    if (!_isWebViewReady) return;
    final timeSignature = widget.exercise.timeSignature;
    final beatsPerMeasure = int.parse(timeSignature.split('/')[0]);
    final beatType = int.parse(timeSignature.split('/')[1]);
    StringBuffer measuresXml = StringBuffer();
    measuresXml.write('<measure number="1">');
    measuresXml.write('<attributes>'
        '<divisions>1</divisions>'
        '<key><fifths>0</fifths></key>'
        '<time><beats>$beatsPerMeasure</beats><beat-type>$beatType</beat-type></time>'
        '<clef><sign>${widget.exercise.clef == 'treble' ? 'G' : 'F'}</sign><line>${widget.exercise.clef == 'treble' ? '2' : '4'}</line></clef>'
        '</attributes>');
    for (var entry in _userSequence.asMap().entries) {
      final index = entry.key;
      final noteData = entry.value.split('_');
      final noteName = noteData[0];
      final figure = noteData[1];
      final step = noteName[0];
      final octave = noteName.substring(1);
      String colorTag = "";
      if (colorizer != null) {
        final isCorrect = index < widget.exercise.correctSequence.length &&
            widget.exercise.correctSequence[index] == entry.value;
        colorTag = colorizer(entry.value, isCorrect);
      }
      final type = figure;
      measuresXml.write("""
      <note $colorTag>
        <pitch><step>$step</step><octave>$octave</octave></pitch>
        <duration>1</duration><type>$type</type>
      </note>
      """);
    }
    measuresXml.write('</measure>');
    final fullXml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
    <score-partwise>
      <part-list><score-part id="P1"><part-name>Music</part-name></score-part></part-list>
      <part id="P1">${measuresXml.toString()}</part>
    </score-partwise>
    """;
    _loadScoreIntoWebView(fullXml);
  }

  void _verifyAnswer() {
    setState(() {
      _isVerified = true;
    });
    final bool isCorrect = const ListEquality()
        .equals(_userSequence, widget.exercise.correctSequence);
    final userSession = context.read<UserSession>();
    _renderUserSequence(
      colorizer: (note, isCorrect) {
        return 'color="${isCorrect ? AppColors.completedHex : AppColors.errorHex}"';
      },
    );
    if (isCorrect) {
      userSession.answerCorrectly();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excelente!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: AppColors.accent, size: 60),
                SizedBox(height: 16),
                Text(
                  'Você transcreveu a melodia perfeitamente!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  '+10 pontos!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.completed),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog() {
    final livesLeft = context.read<UserSession>().currentUser?.lives ?? 0;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sentiment_dissatisfied,
                color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text('Quase lá!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'A sequência não está correta. Compare as notas na pauta.\nVidas restantes: $livesLeft',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _userSequence = [];
                _isVerified = false;
                _selectedNote = widget.exercise.notePalette.isNotEmpty
                    ? widget.exercise.notePalette.first
                    : 'C4';
                _selectedFigure = widget.exercise.figurePalette.isNotEmpty
                    ? widget.exercise.figurePalette.first
                    : 'quarter';
              });
              _renderUserSequence();
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWebViewReady || !_isSoundfontReady) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.exercise.title),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 16),
              Text("Carregando exercício..."),
            ],
          ),
        ),
      );
    }

    final figurePaletteForExercise = {
      for (var key in widget.exercise.figurePalette)
        if (_allFigureNames.containsKey(key)) key: _allFigureNames[key]!
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: Icon(
              _isMetronomeEnabled ? Icons.timer : Icons.timer_off_outlined,
              color: _isMetronomeEnabled ? AppColors.accent : Colors.white54,
            ),
            tooltip: "Metrônomo",
            onPressed: () {
              setState(() {
                _isMetronomeEnabled = !_isMetronomeEnabled;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.hearing),
            tooltip: "Ouvir a melodia",
            onPressed: _isVerified ? null : _playExerciseMelody,
          ),
          if (_isVerified)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Tentar Novamente",
              onPressed: () {
                setState(() {
                  _userSequence = [];
                  _isVerified = false;
                  _selectedNote = widget.exercise.notePalette.isNotEmpty
                      ? widget.exercise.notePalette.first
                      : 'C4';
                  _selectedFigure = widget.exercise.figurePalette.isNotEmpty
                      ? widget.exercise.figurePalette.first
                      : 'quarter';
                });
                _renderUserSequence();
              },
            ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primary.withAlpha(100)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WebViewWidget(controller: _controller),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                MelodicInputPanel(
                  notePalette: widget.exercise.notePalette,
                  figurePalette: figurePaletteForExercise,
                  selectedNote: _selectedNote,
                  selectedFigure: _selectedFigure,
                  isVerified: _isVerified,
                  onNoteSelected: (note) =>
                      setState(() => _selectedNote = note),
                  onFigureSelected: (figure) =>
                      setState(() => _selectedFigure = figure),
                  onAddNote: _addNoteToSequence,
                  onRemoveLastNote: _removeLastNote,
                  onVerify: _verifyAnswer,
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: ValueListenableBuilder<int>(
              valueListenable: _beatCountNotifier,
              builder: (context, beat, child) {
                if (beat == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.card
                          .withAlpha((255 * 0.8).round()), // LINT CORRIGIDO
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2)),
                  child: Text(
                    beat.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                );
              },
            ),
          ),
          ConfettiWidget(
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
        ],
      ),
    );
  }
}
