// lib/features/solfege/presentation/view/solfege_exercise_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';
import 'package:musilingo/features/solfege/data/models/solfege_exercise_model.dart';
import 'package:musilingo/features/solfege/presentation/viewmodel/solfege_exercise_viewmodel.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SolfegeExerciseScreen extends StatefulWidget {
  final SolfegeExercise exercise;

  const SolfegeExerciseScreen({super.key, required this.exercise});

  @override
  State<SolfegeExerciseScreen> createState() => _SolfegeExerciseScreenState();
}

class _SolfegeExerciseScreenState extends State<SolfegeExerciseScreen> {
  // Lógica do MIDI
  final _midiPro = MidiPro();
  int? _instrumentSoundfontId;
  bool _isSoundfontReady = false;

  // Lógica da captura de áudio e pitch
  final _audioRecorder = AudioRecorder();
  final _pitchDetector = PitchDetector();
  late final WebViewController _scoreController;
  StreamSubscription? _audioSubscription;

  // Variáveis para o reconhecimento de fala
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  // Mapa para converter nome da nota em número MIDI
  final Map<String, int> _noteToMidi = {
    'C0': 12,
    'C#0': 13,
    'D0': 14,
    'D#0': 15,
    'E0': 16,
    'F0': 17,
    'F#0': 18,
    'G0': 19,
    'G#0': 20,
    'A0': 21,
    'A#0': 22,
    'B0': 23,
    'C1': 24,
    'C#1': 25,
    'D1': 26,
    'D#1': 27,
    'E1': 28,
    'F1': 29,
    'F#1': 30,
    'G1': 31,
    'G#1': 32,
    'A1': 33,
    'A#1': 34,
    'B1': 35,
    'C2': 36,
    'C#2': 37,
    'D2': 38,
    'D#2': 39,
    'E2': 40,
    'F2': 41,
    'F#2': 42,
    'G2': 43,
    'G#2': 44,
    'A2': 45,
    'A#2': 46,
    'B2': 47,
    'C3': 48,
    'C#3': 49,
    'D3': 50,
    'D#3': 51,
    'E3': 52,
    'F3': 53,
    'F#3': 54,
    'G3': 55,
    'G#3': 56,
    'A3': 57,
    'A#3': 58,
    'B3': 59,
    'C4': 60,
    'C#4': 61,
    'D4': 62,
    'D#4': 63,
    'E4': 64,
    'F4': 65,
    'F#4': 66,
    'G4': 67,
    'G#4': 68,
    'A4': 69,
    'A#4': 70,
    'B4': 71,
    'C5': 72,
    'C#5': 73,
    'D5': 74,
    'D#5': 75,
    'E5': 76,
    'F5': 77,
    'F#5': 78,
    'G5': 79,
    'G#5': 80,
    'A5': 81,
    'A#5': 82,
    'B5': 83,
    'C6': 84,
    'C#6': 85,
    'D6': 86,
    'D#6': 87,
    'E6': 88,
    'F6': 89,
    'F#6': 90,
    'G6': 91,
    'G#6': 92,
    'A6': 93,
    'A#6': 94,
    'B6': 95,
    'C7': 96,
    'C#7': 97,
    'D7': 98,
    'D#7': 99,
    'E7': 100,
    'F7': 101,
    'F#7': 102,
    'G7': 103,
    'G#7': 104,
    'A7': 105,
    'A#7': 106,
    'B7': 107,
    'C8': 108,
    'C#8': 109,
    'D8': 110,
    'D#8': 111,
    'E8': 112,
    'F8': 113,
    'F#8': 114,
    'G8': 115,
    'G#8': 116,
    'A8': 117,
    'A#8': 118,
    'B8': 119
  };

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  Future<void> _initializeDependencies() async {
    _scoreController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadFlutterAsset('assets/osmd_viewer/index.html');

    await _initializeAudio();
    _speechEnabled = await _speechToText.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioSubscription?.cancel();
    _stopSpeechRecognition();
    super.dispose();
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

  Future<void> _playMelody(SolfegeExerciseViewModel viewModel) async {
    if (!_isSoundfontReady || _instrumentSoundfontId == null) {
      return;
    }
    debugPrint("Reproduzindo melodia...");

    final tempo = viewModel.exercise.tempo;
    final beatDuration = Duration(milliseconds: (60000 / tempo).round());

    for (final note in viewModel.exercise.noteSequence) {
      final midiNote =
          _noteToMidi[note.pitch.replaceAll('sharp', '#').toUpperCase()];
      if (midiNote != null) {
        final durationInBeats = viewModel.getDurationInBeats(note.duration);
        final noteDuration = beatDuration * durationInBeats.round();

        // CORRIGIDO: Nomes dos métodos e parâmetros
        _midiPro.playNote(
            sfId: _instrumentSoundfontId!,
            channel: 0,
            key: midiNote,
            velocity: 127);
        await Future.delayed(noteDuration);
        _midiPro.stopNote(
            sfId: _instrumentSoundfontId!, channel: 0, key: midiNote);
      }
    }
  }

  Future<void> _startSolfege(SolfegeExerciseViewModel viewModel) async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission || !_speechEnabled) {
      debugPrint(
          "Permissão para o microfone não concedida ou fala indisponível.");
      return;
    }

    await viewModel.startCountdown();

    _audioSubscription = (await _audioRecorder.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits),
    ))
        .listen((data) async {
      final result = await _pitchDetector.getPitchFromIntBuffer(data);
      if (result.pitched) {
        viewModel.processPitch(result.pitch);
      }
    });

    _startSpeechRecognition(viewModel);
  }

  void _startSpeechRecognition(SolfegeExerciseViewModel viewModel) {
    _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        if (mounted) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
          viewModel.processNoteName(_lastWords);
        }
      },
      listenFor: const Duration(minutes: 2),
      localeId: "pt_BR",
    );
  }

  void _stopSpeechRecognition() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SolfegeExerciseViewModel(exercise: widget.exercise),
      child: Consumer<SolfegeExerciseViewModel>(
        builder: (context, viewModel, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final sanitizedXml = viewModel.musicXml
                  .replaceAll('\\', '\\\\')
                  .replaceAll("'", "\\'")
                  .replaceAll('\n', '\\n')
                  .replaceAll('\r', '');
              _scoreController.runJavaScript("loadScore('$sanitizedXml')");
            }
          });

          return GradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(viewModel.exercise.title),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Stack(
                children: [
                  Center(
                    child: ScoreViewerWidget(controller: _scoreController),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.hearing,
                            label: 'Ouvir',
                            onPressed: _isSoundfontReady
                                ? () => _playMelody(viewModel)
                                : null,
                          ),
                          _buildControlButton(
                            icon: Icons.mic,
                            label: 'Solfejar',
                            onPressed: viewModel.state == SolfegeState.idle
                                ? () => _startSolfege(viewModel)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (viewModel.state == SolfegeState.countdown)
                    _buildCountdownOverlay(viewModel.countdownValue),
                  if (viewModel.state == SolfegeState.finished)
                    _buildResultsModal(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
          ),
          child: Icon(icon, size: 40),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildCountdownOverlay(int value) {
    return Container(
      // CORRIGIDO: 'withOpacity' substituído
      color: Colors.black.withAlpha((255 * 0.7).round()),
      child: Center(
        child: Text(
          // CORRIGIDO: Braces desnecessárias removidas
          '$value',
          style: const TextStyle(
              fontSize: 120, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultsModal(SolfegeExerciseViewModel viewModel) {
    final results = viewModel.results;
    final correctNotesCount = results
        .where((r) => r.wasPitchCorrect && r.wasOnTime && r.wasNameCorrect)
        .length;
    final totalNotes = results.length;
    final allCorrect = correctNotesCount == totalNotes;

    final List<Widget> errorDetails = [];

    if (!allCorrect) {
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (!result.wasPitchCorrect ||
            !result.wasOnTime ||
            !result.wasNameCorrect) {
          final noteName = result.note.pitch;

          String errorDescription = '';
          if (!result.wasOnTime) {
            errorDescription += 'Fora de tempo. ';
          }
          if (!result.wasPitchCorrect && result.userPitch > 0) {
            final difference = result.userPitch - result.note.pitchInHz;
            final direction = difference > 0 ? 'acima' : 'abaixo';
            errorDescription +=
                'Afinação incorreta (${difference.abs().toStringAsFixed(1)}Hz $direction). ';
          }
          if (!result.wasNameCorrect) {
            errorDescription += 'Nome da nota incorreto. ';
          }

          errorDetails.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('Nota ${i + 1} ($noteName): $errorDescription',
                style: const TextStyle(color: Colors.white)),
          ));
        }
      }
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              allCorrect ? 'Parabéns!' : 'Exercício Concluído!',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Sua pontuação: ${viewModel.score}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              allCorrect
                  ? 'Você acertou todas as notas!'
                  : 'Você acertou $correctNotesCount de $totalNotes notas. Veja seus erros abaixo:',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (errorDetails.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...errorDetails,
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
