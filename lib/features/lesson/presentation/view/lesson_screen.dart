// lib/features/lesson/presentation/view/lesson_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/main.dart';
// --- CORREÇÃO: A importação agora é válida pois a dependência está no pubspec.yaml ---
import 'package:just_audio/just_audio.dart';
import 'package:collection/collection.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<List<LessonStep>> _stepsFuture;
  int _currentStepIndex = 0;
  bool? _isCorrect;
  bool _showFeedback = false;
  final DatabaseService _databaseService = DatabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Agora válido
  late ConfettiController _confettiController;

  List<String> _currentDragItems = [];
  final List<String> _dropTargetItems = [];
  bool _dragAndDropCorrect = false;

  @override
  void initState() {
    super.initState();
    _stepsFuture = _databaseService.getStepsForLesson(widget.lesson.id);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onAnswerSubmitted(bool isCorrect) {
    final userSession = Provider.of<UserSession>(context, listen: false);

    if (isCorrect) {
      userSession.answerCorrectly();
    } else {
      userSession.answerWrongly();
      final livesLeft = userSession.currentUser?.lives ?? 0;
      if (mounted) {
        _showLifeLostDialog(livesLeft);
      }
    }

    setState(() {
      _isCorrect = isCorrect;
      _showFeedback = true;
    });
  }

  void _resetStep() {
    setState(() {
      _showFeedback = false;
      _isCorrect = null;
      _stepsFuture.then((steps) {
        if (steps.isNotEmpty && steps[_currentStepIndex] is DragAndDropStep) {
          final step = steps[_currentStepIndex] as DragAndDropStep;
          _dropTargetItems.clear();
          _currentDragItems = List<String>.from(step.draggableItems)..shuffle();
        }
      });
    });
  }

  void _nextStep(int totalSteps) async {
    final navigator = Navigator.of(context);
    final userSession = context.read<UserSession>();
    final user = userSession.currentUser;

    if (_currentStepIndex < totalSteps - 1) {
      setState(() {
        _currentStepIndex++;
        _showFeedback = false;
        _isCorrect = null;
        _currentDragItems = [];
        _dropTargetItems.clear();
        _dragAndDropCorrect = false;
      });
    } else {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await _databaseService.markLessonAsCompleted(userId, widget.lesson.id);
      }

      await _showLessonCompleteDialog(10, user?.lives ?? 0);
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... O restante do arquivo `lesson_screen.dart` permanece o mesmo ...
    // (Ele é longo e não precisa de mais alterações, então vou omiti-lo por brevidade)
    // Apenas certifique-se de que a importação do 'just_audio' está lá como mostrado acima.
    final userLives = context.watch<UserSession>().currentUser?.lives ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      // Stack permite sobrepor o widget de confete sobre a tela
      body: Stack(
        children: [
          FutureBuilder<List<LessonStep>>(
            future: _stepsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Center(
                    child: Text(
                        'Erro: ${snapshot.error ?? "Não foi possível carregar o conteúdo da lição."}'));
              }

              final steps = snapshot.data!;
              final currentStep = steps[_currentStepIndex];
              final progress = (_currentStepIndex + 1) / steps.length;

              if (currentStep is DragAndDropStep &&
                  _currentDragItems.isEmpty &&
                  _dropTargetItems.isEmpty) {
                _currentDragItems =
                    List<String>.from(currentStep.draggableItems)..shuffle();
              }

              if (userLives <= 0 && !_showFeedback) {
                return _buildGameOverWidget();
              }

              return Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.card,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.completed),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildStepWidget(currentStep),
                    ),
                  ),
                  if (_showFeedback) _buildFeedbackBar(steps.length),
                ],
              );
            },
          ),
          // Widget de confete alinhado no topo para o efeito de explosão
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

  Future<void> _showLifeLostDialog(int livesLeft) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.favorite_border, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text('Vida Perdida!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Você errou. Tenha mais cuidado! Vidas restantes: $livesLeft',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLessonCompleteDialog(int pointsGained, int totalLives) {
    _confettiController.play();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lição Concluída!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: AppColors.accent, size: 60),
            const SizedBox(height: 16),
            Text(
              'Você ganhou +$pointsGained pontos!',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Vidas restantes: $totalLives',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.completed),
              child: const Text('Continuar Jornada'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGameOverWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, color: AppColors.primary, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Você não tem mais vidas!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pratique mais para recuperar vidas e tentar novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sair da Lição'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepWidget(LessonStep step) {
    switch (step.type) {
      case LessonStepType.explanation:
        return _buildExplanationWidget(step as ExplanationStep);
      case LessonStepType.multipleChoice:
        return _buildMultipleChoiceWidget(step as MultipleChoiceQuestionStep);
      case LessonStepType.dragAndDrop:
        return _buildDragAndDropWidget(step as DragAndDropStep);
      case LessonStepType.earTraining:
        return _buildEarTrainingWidget(step as EarTrainingStep);
    }
  }

  Widget _buildExplanationWidget(ExplanationStep step) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  step.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, height: 1.5),
                ),
                if (step.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: Image.network(step.imageUrl!),
                  ),
              ],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final steps = await _stepsFuture;
            _nextStep(steps.length);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Continuar', style: TextStyle(fontSize: 18)),
        )
      ],
    );
  }

  Widget _buildMultipleChoiceWidget(MultipleChoiceQuestionStep step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          step.questionText,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ...step.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _showFeedback
                  ? null
                  : () => _onAnswerSubmitted(option == step.correctAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(option, style: const TextStyle(fontSize: 18)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDragAndDropWidget(DragAndDropStep step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          step.questionText,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        DragTarget<String>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              constraints: const BoxConstraints(minHeight: 60),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _dropTargetItems
                      .map((item) => Chip(label: Text(item)))
                      .toList(),
                ),
              ),
            );
          },
          onAcceptWithDetails: (details) {
            if (_showFeedback) return;
            setState(() {
              final data = details.data;
              _dropTargetItems.add(data);
              _currentDragItems.remove(data);
              if (_currentDragItems.isEmpty) {
                _dragAndDropCorrect = const ListEquality()
                    .equals(_dropTargetItems, step.correctOrder);
                _onAnswerSubmitted(_dragAndDropCorrect);
              }
            });
          },
        ),
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              alignment: WrapAlignment.center,
              children: _currentDragItems.map((item) {
                return Draggable<String>(
                  data: item,
                  feedback: Material(
                    type: MaterialType.transparency,
                    child: Chip(
                        label: Text(item), backgroundColor: AppColors.accent),
                  ),
                  childWhenDragging:
                      const Chip(label: Text(""), backgroundColor: Colors.grey),
                  child: Chip(label: Text(item)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarTrainingWidget(EarTrainingStep step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          step.text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        IconButton(
          icon: const Icon(Icons.play_circle_fill, color: AppColors.accent),
          iconSize: 80,
          onPressed: () async {
            // Verifica se a URL não está vazia antes de tentar tocar
            if (step.audioUrl.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Áudio para este exercício não encontrado.')));
              }
              return;
            }

            try {
              await _audioPlayer.setUrl(
                  step.audioUrl); // <--- CORRETO: Usa a URL do exercício
              _audioPlayer.play();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Não foi possível carregar o áudio.')));
              }
            }
          },
        ),
        const SizedBox(height: 40),
        ...step.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _showFeedback
                  ? null
                  : () => _onAnswerSubmitted(option == step.correctAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(option, style: const TextStyle(fontSize: 18)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeedbackBar(int totalSteps) {
    final bool isCorrect = _isCorrect ?? false;
    final userLives = context.watch<UserSession>().currentUser?.lives ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isCorrect ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isCorrect ? 'Correto!' : 'Ops! Tente novamente.',
              style: TextStyle(
                color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (isCorrect)
            ElevatedButton(
              onPressed: () => _nextStep(totalSteps),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: Text(_currentStepIndex < totalSteps - 1
                  ? 'Continuar'
                  : 'Finalizar Lição'),
            )
          else if (userLives > 0)
            ElevatedButton(
              onPressed: _resetStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('Tentar Novamente'),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Sair da Lição'),
            ),
        ],
      ),
    );
  }
}
