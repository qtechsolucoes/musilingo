// lib/features/practice/presentation/view/melodic_perception_exercise_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Classe de utilidades para conversões e lógicas musicais
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
    if (noteName.length < 2) return 60; // Retorna Dó central como padrão
    try {
      final octave = int.parse(noteName.substring(noteName.length - 1));
      final key = noteName.substring(0, noteName.length - 1).toUpperCase();
      if (!_noteValues.containsKey(key)) return 60;
      return _noteValues[key]! + (octave + 1) * 12;
    } catch (e) {
      return 60;
    }
  }

  // Mapeamento de nomes internos (inglês) para valores de duração (semínima = 1.0)
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
  final FlutterMidi _flutterMidi = FlutterMidi();
  bool _isWebViewReady = false;
  bool _isSoundfontReady = false;

  List<String> _userSequence = [];
  bool _isVerified = false;
  final List<String> _notePalette = [
    "C4",
    "D4",
    "E4",
    "F4",
    "G4",
    "A4",
    "B4",
    "C5"
  ];

  // Paleta de figuras com nomes, valores e símbolos
  final Map<String, String> _figurePalette = {
    'whole': 'Semibreve (𝅝)',
    'half': 'Mínima (𝅗𝅥)',
    'quarter': 'Semínima (♩)',
    'eighth': 'Colcheia (♪)',
    '16th': 'Semicolcheia (♬)',
  };
  String _selectedNote = "C4";
  String _selectedFigure = "quarter"; // Valor interno em inglês

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    await _loadSoundfont();

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
              _renderBlankStaff();
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/web/index.html');
  }

  Future<void> _loadSoundfont() async {
    try {
      _flutterMidi.unmute();
      ByteData sf2 = await rootBundle.load('assets/sf2/GeneralUserGS.sf2');
      await _flutterMidi.prepare(sf2: sf2, name: 'GeneralUserGS.sf2');
      if (mounted) {
        setState(() {
          _isSoundfontReady = true;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar o soundfont: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro fatal ao carregar sons: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  Future<void> _playExerciseMelody() async {
    if (!_isSoundfontReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Instrumentos ainda não estão prontos.'),
      ));
      return;
    }
    const double bpm = 100.0;
    const double quarterNoteDurationMs = 60000.0 / bpm;

    for (String noteData in widget.exercise.correctSequence) {
      final parts = noteData.split('_');
      final noteName = parts[0];
      final durationName = parts[1];

      final midiNote = MusicUtils.noteNameToMidi(noteName);
      final durationMultiplier =
          MusicUtils.figureDurations[durationName] ?? 1.0;
      final noteDuration = (quarterNoteDurationMs * durationMultiplier).round();

      _flutterMidi.playMidiNote(midi: midiNote);
      await Future.delayed(Duration(milliseconds: noteDuration));
      _flutterMidi.stopMidiNote(midi: midiNote);
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A figura não cabe neste compasso!'),
        backgroundColor: Colors.redAccent,
      ));
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

  void _renderUserSequence(
      {String Function(String note, bool isCorrect)? colorizer}) {
    final timeSignature = widget.exercise.timeSignature;
    final beatsPerMeasure = int.parse(timeSignature.split('/')[0]);
    final beatType = int.parse(timeSignature.split('/')[1]);
    final measureCapacity = beatsPerMeasure * (4.0 / beatType);

    StringBuffer measuresXml = StringBuffer();
    double currentMeasureDuration = 0;
    int measureNumber = 1;

    measuresXml.write('<measure number="$measureNumber">');
    if (measureNumber == 1) {
      measuresXml.write(
          '<attributes><divisions>4</divisions><key><fifths>0</fifths></key>');
      measuresXml.write(
          '<time><beats>$beatsPerMeasure</beats><beat-type>$beatType</beat-type></time>');
      measuresXml.write(
          '<clef><sign>${widget.exercise.clef == 'treble' ? 'G' : 'F'}</sign><line>${widget.exercise.clef == 'treble' ? '2' : '4'}</line></clef></attributes>');
    }

    for (var entry in _userSequence.asMap().entries) {
      final index = entry.key;
      final noteData = entry.value.split('_');
      final noteName = noteData[0];
      final figure = noteData[1];
      final step = noteName[0];
      final octave = noteName.substring(1);
      final noteDuration = MusicUtils.figureDurations[figure] ?? 0;

      String colorTag = "";
      if (colorizer != null) {
        final isCorrect = index < widget.exercise.correctSequence.length &&
            widget.exercise.correctSequence[index] == entry.value;
        colorTag = colorizer(entry.value, isCorrect);
      }

      final xmlDuration = (noteDuration * 4).toInt();

      measuresXml.write("""
      <note $colorTag>
        <pitch><step>$step</step><octave>$octave</octave></pitch>
        <duration>$xmlDuration</duration><type>$figure</type>
      </note>
      """);

      currentMeasureDuration += noteDuration;
      if (currentMeasureDuration >= measureCapacity) {
        measuresXml.write('</measure>');
        measureNumber++;
        measuresXml.write('<measure number="$measureNumber">');
        currentMeasureDuration = 0;
      }
    }

    if (!measuresXml.toString().endsWith('</measure>')) {
      measuresXml.write('</measure>');
    }

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

  void _renderBlankStaff() {
    // Usa o MusicXML que veio do banco de dados para a pauta em branco
    _loadScoreIntoWebView(widget.exercise.musicXml);
  }

  void _verifyAnswer() {
    setState(() {
      _isVerified = true;
    });
    _renderUserSequence(colorizer: (note, isCorrect) {
      return 'color="${isCorrect ? '#4CAF50' : '#F44336'}"';
    });
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
              Text("Carregando..."),
            ],
          )));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.hearing),
            tooltip: "Ouvir a melodia",
            onPressed: _playExerciseMelody,
          ),
          if (_isVerified)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Tentar Novamente",
              onPressed: () {
                setState(() {
                  _userSequence = [];
                  _isVerified = false;
                });
                _renderBlankStaff();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(100)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _notePalette
                                  .map((note) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: ActionChip(
                                          label: Text(note),
                                          backgroundColor: _selectedNote == note
                                              ? AppColors.accent
                                              : AppColors.primary,
                                          onPressed: () => setState(
                                              () => _selectedNote = note),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _figurePalette.entries
                                  .map((entry) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: ActionChip(
                                          label: Text(entry.value),
                                          backgroundColor:
                                              _selectedFigure == entry.key
                                                  ? AppColors.accent
                                                  : AppColors.primary,
                                          onPressed: () => setState(() =>
                                              _selectedFigure = entry.key),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(
                      width: 24,
                      indent: 8,
                      endIndent: 8,
                      color: Colors.white24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _addNoteToSequence,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Nota"),
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12)),
                            ),
                            ElevatedButton.icon(
                              onPressed: _removeLastNote,
                              icon: const Icon(Icons.undo, size: 18),
                              label: const Text("Desfazer"),
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12)),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isVerified ? null : _verifyAnswer,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.completed),
                            child: const Text('Verificar Resposta'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
