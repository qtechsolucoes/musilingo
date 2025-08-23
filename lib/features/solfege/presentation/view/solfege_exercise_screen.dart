// lib/features/solfege/presentation/view/solfege_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';
import 'package:musilingo/features/solfege/data/models/solfege_exercise_model.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _scoreController;
  int? _instrumentSoundfontId;
  bool _isSoundfontReady = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Cria e configura o controller do WebView
    _scoreController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Quando a página HTML carregar, desenha a partitura
            _loadScore();
          },
        ),
      )
      ..loadFlutterAsset('assets/osmd_viewer/index.html');

    _initializeAudio();
  }

  String _convertExerciseToMusicXml(SolfegeExercise exercise) {
    const durationMap = {
      'whole': 'whole',
      'half': 'half',
      'quarter': 'quarter',
      'eighth': 'eighth',
      '16th': '16th',
      '32nd': '32nd',
    };

    final notesXml = exercise.noteSequence.map((note) {
      final pitch = note.pitch.replaceAll('sharp', '#').replaceAll('flat', 'b');
      final step = pitch.substring(0, 1).toUpperCase();
      final octave = pitch.replaceAll(RegExp(r'[^0-9]'), '');

      String alter = '';
      if (pitch.contains('#')) {
        alter = '<alter>1</alter>';
      } else if (pitch.contains('b')) {
        alter = '<alter>-1</alter>';
      }

      final type = durationMap[note.duration.toLowerCase()] ?? 'quarter';

      return '''
        <note>
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
          <score-part id="P1">
            <part-name>Music</part-name>
          </score-part>
        </part-list>
        <part id="P1">
          <measure number="1">
            <attributes>
              <divisions>1</divisions>
              <key><fifths>0</fifths></key>
              <time>
                <beats>${exercise.timeSignature.split('/')[0]}</beats>
                <beat-type>${exercise.timeSignature.split('/')[1]}</beat-type>
              </time>
              <clef>
                <sign>${exercise.clef.toLowerCase() == 'treble' ? 'G' : 'F'}</sign>
                <line>${exercise.clef.toLowerCase() == 'treble' ? '2' : '4'}</line>
              </clef>
            </attributes>
            $notesXml
          </measure>
        </part>
      </score-partwise>
    ''';
  }

  void _loadScore() {
    final musicXml = _convertExerciseToMusicXml(widget.exercise);
    final sanitizedXml = musicXml
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
    _scoreController.runJavaScript("loadScore('$sanitizedXml')");
  }

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

  int _noteToMidi(String pitchStr) {
    final noteString = pitchStr.toUpperCase();
    final octave = int.parse(noteString.replaceAll(RegExp(r'[^0-9]'), ''));
    final noteName = noteString.replaceAll(RegExp(r'[0-9]'), '');

    const noteValues = {
      'C': 0,
      'C#': 1,
      'D': 2,
      'D#': 3,
      'E': 4,
      'F': 5,
      'F#': 6,
      'G': 7,
      'G#': 8,
      'A': 9,
      'A#': 10,
      'B': 11,
    };

    final midiValue = noteValues[noteName.replaceAll("SHARP", "#")] ?? -1;
    if (midiValue == -1) {
      return 0;
    }
    return midiValue + (octave + 1) * 12;
  }

  Future<void> _playMelody() async {
    if (!_isSoundfontReady || _instrumentSoundfontId == null || _isPlaying) {
      return;
    }

    setState(() => _isPlaying = true);

    final int bpm = widget.exercise.tempo;
    final double beatDurationMs = 60000.0 / bpm;
    const beatsMap = {
      'whole': 4.0,
      'half': 2.0,
      'quarter': 1.0,
      'eighth': 0.5,
      '16th': 0.25,
      '32nd': 0.125,
    };

    for (int i = 0; i < widget.exercise.noteSequence.length; i++) {
      if (!mounted) {
        break;
      }

      final noteData = widget.exercise.noteSequence[i];
      final midiNote = _noteToMidi(noteData.pitch);
      final numBeats = beatsMap[noteData.duration.toLowerCase()] ?? 1.0;
      final durationInMs = (beatDurationMs * numBeats).round();

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

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.exercise.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow,
                  color: _isSoundfontReady ? Colors.white : Colors.white54),
              onPressed: _isSoundfontReady ? _playMelody : null,
              tooltip: 'Ouvir Melodia',
            ),
          ],
        ),
        body: Center(
          child: ScoreViewerWidget(
            controller: _scoreController,
          ),
        ),
      ),
    );
  }
}
