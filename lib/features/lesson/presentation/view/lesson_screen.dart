// lib/features/lesson/presentation/view/lesson_screen.dart

import 'package:collection/collection.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/features/lesson/data/models/drag_drop_question_model.dart';
import 'package:musilingo/features/lesson/data/models/ear_training_question_model.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/features/lesson/data/models/question_model.dart';
import 'package:musilingo/main.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Future<List<LessonStep>> _stepsFuture;
  List<LessonStep> _steps = [];

  int _currentStepIndex = 0;
  String? _selectedAnswer;
  bool? _isCorrect;
  late final AudioPlayer _audioPlayer;
  List<DragAndDropList> _dndLists = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _stepsFuture = _fetchLessonSteps();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<List<LessonStep>> _fetchLessonSteps() async {
    try {
      final response = await supabase
          .from('lesson_steps')
          .select()
          .eq('lesson_id', widget.lesson.id)
          .order('order', ascending: true);

      final steps = List<LessonStep>.from(
        response.map((map) => LessonStep.fromMap(map as Map<String, dynamic>)),
      );

      if (mounted) {
        setState(() {
          _steps = steps;
        });
        _setupStep();
      }

      return steps;

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar conteúdo da lição: $e'))
        );
      }
      return [];
    }
  }

  void _setupStep() {
    if (_steps.isEmpty || _currentStepIndex >= _steps.length) return;
    final currentStep = _steps[_currentStepIndex];
    if (currentStep.type == LessonStepType.dragAndDrop) {
      _setupDragAndDrop(currentStep as DragAndDropStep);
    }
  }

  void _setupDragAndDrop(DragAndDropStep step) {
    final question = step.question;
    setState(() {
      _dndLists = [
        DragAndDropList(
          header: const Text('Notas Disponíveis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          children: question.options.map((note) => DragAndDropItem(child: _buildNoteTile(note.name))).toList(),
        ),
        DragAndDropList(
          header: const Text('Arraste as notas aqui', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          children: const [],
          canDrag: false,
        ),
      ];
    });
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _selectedAnswer = null;
        _isCorrect = null;
      });
      _setupStep();
    } else {
      _showCompletionDialog();
    }
  }

  void _answerQuestion(String selectedAnswer, String correctAnswer) {
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = selectedAnswer;
      _isCorrect = selectedAnswer == correctAnswer;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_isCorrect!) {
        _nextStep();
      } else {
        setState(() {
          _selectedAnswer = null;
          _isCorrect = null;
        });
      }
    });
  }

  void _showCompletionDialog() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('user_lesson_progress').upsert({
        'user_id': userId,
        'lesson_id': widget.lesson.id,
      });

    } catch (e) {
      // O erro é tratado silenciosamente para não interromper o fluxo do usuário.
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Parabéns!', style: TextStyle(color: AppColors.accent)),
        content: const Text('Você completou a lição com sucesso.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('CONTINUAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: LinearProgressIndicator(
          value: _steps.isEmpty ? 0 : (_currentStepIndex + 1) / _steps.length,
          backgroundColor: Colors.grey.shade700,
          color: AppColors.accent,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.favorite, color: AppColors.primary),
                SizedBox(width: 4),
                Text('5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<LessonStep>>(
          future: _stepsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _steps.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar a lição.'));
            }
            final currentStep = _steps[_currentStepIndex];
            return _buildStepContent(currentStep);
          },
        ),
      ),
    );
  }

  Widget _buildStepContent(LessonStep step) {
    switch (step.type) {
      case LessonStepType.theory:
        return _buildTheoryStep(step as TheoryStep);
      case LessonStepType.question:
        return _buildQuestionStep(step as QuestionStep);
      case LessonStepType.earTraining:
        return _buildEarTrainingStep(step as EarTrainingStep);
      case LessonStepType.dragAndDrop:
        return _buildDragAndDropStep(step as DragAndDropStep);
      default:
        return const Center(child: Text("Este tipo de exercício ainda não foi implementado."));
    }
  }

  Widget _buildTheoryStep(TheoryStep step) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(step.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text(step.content, style: TextStyle(fontSize: 18, color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('CONTINUAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.background)),
        ),
      ],
    );
  }

  Widget _buildQuestionStep(QuestionStep step) {
    final question = step.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question.statement, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (question.imageAsset != null) SvgPicture.asset(question.imageAsset!, height: 100),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: question.options.map((option) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(option, question.correctAnswer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonColor(option, question.correctAnswer),
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    child: Text(option, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarTrainingStep(EarTrainingStep step) {
    return Center(child: Text("Exercício de Treinamento Auditivo - ${step.question.statement}"));
  }

  Widget _buildDragAndDropStep(DragAndDropStep step) {
    return Center(child: Text("Exercício de Arrastar e Soltar - ${step.question.statement}"));
  }

  Color _getButtonColor(String option, String correctAnswer) {
    if (_selectedAnswer == null) return AppColors.card;
    if (option == _selectedAnswer) return _isCorrect! ? Colors.green : AppColors.primary;
    if (option == correctAnswer) return Colors.green;
    return AppColors.card;
  }

  // --- MÉTODO CORRIGIDO E ADICIONADO AQUI ---
  Widget _buildNoteTile(String noteName) {
    return ListTile(
      tileColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(noteName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      leading: const Icon(Icons.music_note, color: AppColors.accent),
    );
  }
}