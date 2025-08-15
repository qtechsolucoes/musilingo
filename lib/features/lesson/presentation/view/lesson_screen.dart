// lib/features/lesson/presentation/view/lesson_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/main.dart';
import 'package:just_audio/just_audio.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  // ESTADO PARA O NOVO WIDGET DE ARRASTAR E SOLTAR
  List<String> _dragSourceItems = []; // Itens que podem ser arrastados
  final Map<int, String?> _dropTargetMatches =
      {}; // Mapa do que foi solto em cada alvo

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

  void _setupDragAndDropState(DragAndDropStep step) {
    if (_dragSourceItems.isEmpty && _dropTargetMatches.isEmpty) {
      _dragSourceItems = List<String>.from(step.draggableItems)..shuffle();
      for (int i = 0; i < step.correctOrder.length; i++) {
        _dropTargetMatches[i] = null;
      }
    }
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

  void _checkDragAndDropAnswer(DragAndDropStep step) {
    final correctMatches =
        Map.fromIterables(step.draggableItems, step.correctOrder);
    bool allCorrect = true;

    for (int i = 0; i < step.correctOrder.length; i++) {
      final userPlacedItem = _dropTargetMatches[i];
      final correctDefinition = step.correctOrder[i];

      final correctKey = correctMatches.entries
          .firstWhere((entry) => entry.value == correctDefinition)
          .key;

      if (userPlacedItem != correctKey) {
        allCorrect = false;
        break;
      }
    }
    _onAnswerSubmitted(allCorrect);
  }

  void _resetStep() {
    setState(() {
      _showFeedback = false;
      _isCorrect = null;
      _stepsFuture.then((steps) {
        if (steps.isNotEmpty && steps[_currentStepIndex] is DragAndDropStep) {
          final step = steps[_currentStepIndex] as DragAndDropStep;
          _dragSourceItems.clear();
          _dropTargetMatches.clear();
          _setupDragAndDropState(step);
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
        _dragSourceItems = [];
        _dropTargetMatches.clear();
      });
    } else {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await _databaseService.markLessonAsCompleted(userId, widget.lesson.id);
        await userSession.recordPractice();
      }

      await _showLessonCompleteDialog(10, user?.lives ?? 0);
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLives = context.watch<UserSession>().currentUser?.lives ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
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

              if (currentStep is DragAndDropStep) {
                _setupDragAndDropState(currentStep);
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
                  if (currentStep is! DragAndDropStep && _showFeedback)
                    _buildFeedbackBar(steps.length)
                  else if (currentStep is DragAndDropStep && !_showFeedback)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () => _checkDragAndDropAnswer(currentStep),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.completed,
                            minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Verificar',
                            style: TextStyle(fontSize: 18)),
                      ),
                    )
                  else if (currentStep is DragAndDropStep && _showFeedback)
                    _buildFeedbackBar(steps.length),
                ],
              );
            },
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
      children: [
        Text(
          step.questionText,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: List.generate(step.correctOrder.length, (index) {
                    return DragTarget<String>(
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          height: 60,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 100,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _dropTargetMatches[index] != null
                                      ? AppColors.accent
                                      : AppColors.primary,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      bottomLeft: Radius.circular(11)),
                                ),
                                child: _dropTargetMatches[index] != null
                                    ? Center(
                                        child: Text(_dropTargetMatches[index]!,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.background)))
                                    : null,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(step.correctOrder[index],
                                      style: const TextStyle(
                                          color: AppColors.textSecondary)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onWillAcceptWithDetails: (details) =>
                          !_dropTargetMatches.containsValue(details.data),
                      onAcceptWithDetails: (details) {
                        setState(() {
                          _dropTargetMatches[index] = details.data;
                          _dragSourceItems.remove(details.data);
                        });
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _dragSourceItems.map((item) {
                    return Draggable<String>(
                      data: item,
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: Chip(
                            label: Text(item),
                            backgroundColor: AppColors.accent,
                            labelStyle: const TextStyle(
                                color: AppColors.background,
                                fontWeight: FontWeight.bold)),
                      ),
                      childWhenDragging: Chip(
                          label: Text(item), backgroundColor: AppColors.card),
                      child: Chip(label: Text(item)),
                    );
                  }).toList(),
                ),
              ),
            ],
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
            if (step.audioUrl.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Áudio para este exercício não encontrado.')));
              }
              return;
            }
            try {
              await _audioPlayer.setUrl(step.audioUrl);
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
                  backgroundColor: Colors.green.shade600),
              child: Text(_currentStepIndex < totalSteps - 1
                  ? 'Continuar'
                  : 'Finalizar Lição'),
            )
          else if (userLives > 0)
            ElevatedButton(
              onPressed: _resetStep,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600),
              child: const Text('Tentar Novamente'),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Sair da Lição'),
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
}
