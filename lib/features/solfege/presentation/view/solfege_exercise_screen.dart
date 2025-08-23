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
  final _pitchDetector = PitchDetector(44100, 2048);
  late final WebViewController _scoreController;
  StreamSubscription? _audioSubscription;
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    // Cria e configura o controller do WebView
    _scoreController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadFlutterAsset('assets/osmd_viewer/index.html');

    _initializeAudio();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioSubscription?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  // --- LÓGICA DE CARREGAMENTO E REPRODUÇÃO DE ÁUDIO ---

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

  Future<void> _playMelody() async {
    if (!_isSoundfontReady || _instrumentSoundfontId == null) {
      return;
    }

    // Implementação da reprodução da melodia usando _midiPro
    // (Lógica completa omitida por brevidade, mas você pode usar o código anterior)
    debugPrint("Reproduzindo melodia...");
  }

  // --- LÓGICA DO EXERCÍCIO DE SOLFEJO ---

  Future<void> _startSolfege() async {
    final viewModel = context.read<SolfegeExerciseViewModel>();

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      debugPrint("Permissão para o microfone não concedida.");
      return;
    }

    await viewModel.startCountdown();

    _audioSubscription = (await _audioRecorder.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits),
    ))
        .listen((data) {
      final result = _pitchDetector.getPitch(data);
      if (result.pitched) {
        viewModel.processPitch(result.pitch);
      }
    });

    _startExerciseEngine();
  }

  void _startExerciseEngine() {
    final viewModel = context.read<SolfegeExerciseViewModel>();
    final tempo = viewModel.exercise.tempo;
    final beatDuration = Duration(milliseconds: (60000 / tempo).round());
    final totalNotes = viewModel.exercise.noteSequence.length;

    int notesEvaluated = 0;

    _gameTimer = Timer.periodic(beatDuration, (timer) {
      if (viewModel.state != SolfegeState.listening) {
        timer.cancel();
        _audioRecorder.stop();
        _audioSubscription?.cancel();
        return;
      }

      // Lógica para avançar para a próxima nota.
      // O pitch real do usuário seria capturado e processado no .listen() acima.
      // Aqui, apenas avançamos a nota no tempo e avaliamos se algo foi cantado.
      final note = viewModel.exercise.noteSequence[notesEvaluated];
      final duration = viewModel.getDurationInBeats(note.duration).round();

      for (int i = 0; i < duration; i++) {
        // Simula a avaliação de uma nota. A lógica real vai aqui.
        // Por agora, assumimos que o usuário não cantou nada e a nota falhou.
        viewModel.advanceToNextNote(userPitch: 0, wasOnTime: true);
        notesEvaluated++;
      }

      if (notesEvaluated >= totalNotes) {
        timer.cancel();
        viewModel.finishExercise();
      }
    });
  }

  // --- CONSTRUÇÃO DA INTERFACE ---

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SolfegeExerciseViewModel(exercise: widget.exercise),
      child: Consumer<SolfegeExerciseViewModel>(
        builder: (context, viewModel, child) {
          // Carrega a partitura sempre que o musicXml do viewModel mudar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final sanitizedXml = viewModel.musicXml
                .replaceAll('\\', '\\\\')
                .replaceAll("'", "\\'")
                .replaceAll('\n', '\\n')
                .replaceAll('\r', '');
            _scoreController.runJavaScript("loadScore('$sanitizedXml')");
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
                  // Partitura no centro
                  Center(
                    child: ScoreViewerWidget(controller: _scoreController),
                  ),

                  // Botoões
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
                            onPressed: _isSoundfontReady ? _playMelody : null,
                          ),
                          _buildControlButton(
                            icon: Icons.mic,
                            label: 'Solfejar',
                            onPressed: viewModel.state == SolfegeState.idle
                                ? _startSolfege
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overlay para a contagem decrescente
                  if (viewModel.state == SolfegeState.countdown)
                    _buildCountdownOverlay(viewModel.countdownValue),

                  // Overlay para o modal de resultados
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
      // ignore: deprecated_member_use
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
              fontSize: 120, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultsModal(SolfegeExerciseViewModel viewModel) {
    // Implementação completa do modal de resultados aqui.
    // Pode ser um AlertDialog ou um widget customizado.
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 300,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Exercício Concluído!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(viewModel.feedbackMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reinicia o exercício
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
