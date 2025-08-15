// lib/features/practice/presentation/view/harmonic_progression_exercise_screen.dart

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/harmonic_progression_model.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/practice/presentation/view/melodic_perception_exercise_screen.dart'; // Reutilizamos o MusicUtils
import 'package:provider/provider.dart';

class HarmonicProgressionExerciseScreen extends StatefulWidget {
  final HarmonicProgression exercise;

  const HarmonicProgressionExerciseScreen({super.key, required this.exercise});

  @override
  State<HarmonicProgressionExerciseScreen> createState() =>
      _HarmonicProgressionExerciseScreenState();
}

class _HarmonicProgressionExerciseScreenState
    extends State<HarmonicProgressionExerciseScreen> {
  final _midiPro = MidiPro();
  late ConfettiController _confettiController;
  bool _showFeedback = false;
  bool? _isCorrect;
  bool _isPlaying = false;

  int? _instrumentSoundfontId;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadSoundfont();
  }

  Future<void> _loadSoundfont() async {
    final sfId = await _midiPro.loadSoundfont(
      path: 'assets/sf2/GeneralUserGS.sf2',
      bank: 0,
      program: 0, // Piano
    );
    if (mounted) {
      setState(() {
        _instrumentSoundfontId = sfId;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _playProgression() async {
    if (_instrumentSoundfontId == null || _isPlaying) return;
    setState(() => _isPlaying = true);

    // Itera sobre cada acorde na progressão
    for (final chordNotes in widget.exercise.progression) {
      final midiNotes = chordNotes
          .map((noteName) => MusicUtils.noteNameToMidi(noteName))
          .toList();

      // Toca todas as notas do acorde atual
      for (final note in midiNotes) {
        _midiPro.playNote(
            sfId: _instrumentSoundfontId!,
            channel: 0,
            key: note,
            velocity: 127);
      }

      // Mantém o acorde a soar por 1.5 segundos
      await Future.delayed(const Duration(milliseconds: 1500));

      // Para todas as notas do acorde atual
      for (final note in midiNotes) {
        _midiPro.stopNote(sfId: _instrumentSoundfontId!, channel: 0, key: note);
      }

      // Pequena pausa antes do próximo acorde
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) setState(() => _isPlaying = false);
  }

  void _onAnswerSubmitted(String selectedOption) {
    final userSession = context.read<UserSession>();
    final isCorrect = selectedOption == widget.exercise.correctAnswer;

    if (isCorrect) {
      userSession.answerCorrectly();
      userSession.recordPractice();
    } else {
      userSession.answerWrongly();
    }

    setState(() {
      _isCorrect = isCorrect;
      _showFeedback = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        backgroundColor: AppColors.background,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill,
                      color: AppColors.accent),
                  iconSize: 120,
                  onPressed: _instrumentSoundfontId != null && !_isPlaying
                      ? _playProgression
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ouvir a progressão em ${widget.exercise.key}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(flex: 3),
                ...widget.exercise.options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: _showFeedback || _isPlaying
                          ? null
                          : () => _onAnswerSubmitted(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(option, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }),
                const Spacer(flex: 1),
              ],
            ),
          ),
          if (_showFeedback)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildFeedbackBar(),
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
    );
  }

  Widget _buildFeedbackBar() {
    final bool isCorrect = _isCorrect ?? false;
    if (isCorrect) {
      _confettiController.play();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      color: isCorrect ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              isCorrect ? 'Correto!' : 'Resposta incorreta. Tente novamente!',
              style: TextStyle(
                color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (isCorrect) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _showFeedback = false;
                  _isCorrect = null;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCorrect ? Colors.green.shade600 : Colors.red.shade600,
            ),
            child: Text(isCorrect ? 'Continuar' : 'Tentar Novamente'),
          )
        ],
      ),
    );
  }
}
