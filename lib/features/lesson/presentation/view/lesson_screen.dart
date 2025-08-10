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

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _currentStepIndex = 0;
  String? _selectedAnswer;
  bool? _isCorrect;
  late final AudioPlayer _audioPlayer;
  List<DragAndDropList> _dndLists = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupStep();
  }

  @override
  void didUpdateWidget(covariant LessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupStep();
  }

  void _setupStep() {
    if (widget.lesson.steps.isEmpty) return;
    final currentStep = widget.lesson.steps[_currentStepIndex];
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
          children: [],
          canDrag: false,
        ),
      ];
    });
  }

  void _nextStep() {
    if (_currentStepIndex < widget.lesson.steps.length - 1) {
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

  void _showCompletionDialog() {
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
    if (widget.lesson.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 80, color: AppColors.accent),
              SizedBox(height: 20),
              Text('Lição em Breve!', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      );
    }

    final currentStep = widget.lesson.steps[_currentStepIndex];
    final progress = (_currentStepIndex) / widget.lesson.steps.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: LinearProgressIndicator(
          value: progress,
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
        child: _buildStepContent(currentStep),
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
    }
  }

  Widget _buildTheoryStep(TheoryStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(step.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text(step.content, style: TextStyle(fontSize: 18, color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('CONTINUAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
        ),
      ],
    );
  }

  Widget _buildQuestionStep(QuestionStep step) {
    final question = step.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question.statement, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        if (question.imageAsset != null)
          SvgPicture.asset(question.imageAsset!, height: 150)
        else
          const SizedBox(height: 150),
        const SizedBox(height: 24),
        ...question.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () => _answerQuestion(option, question.correctAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(option, question.correctAnswer),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              child: Text(option, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEarTrainingStep(EarTrainingStep step) {
    final question = step.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question.statement, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tocando som... (Simulação)')),
            );
          },
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 3),
            ),
            child: const Center(
              child: Icon(Icons.volume_up, size: 80, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...question.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () => _answerQuestion(option, question.correctAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(option, question.correctAnswer),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              child: Text(option, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDragAndDropStep(DragAndDropStep step) {
    final question = step.question;
    return Column(
      children: [
        Text(question.statement, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(
          child: DragAndDropLists(
            children: _dndLists,
            onItemReorder: (int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
              setState(() {
                final movedItem = _dndLists[oldListIndex].children.removeAt(oldItemIndex);
                _dndLists[newListIndex].children.insert(newItemIndex, movedItem);
              });
            },
            onListReorder: (int oldListIndex, int newListIndex) {},
            listPadding: const EdgeInsets.symmetric(vertical: 10),
            itemDecorationWhileDragging: BoxDecoration(
              color: AppColors.accent.withOpacity(0.5),
              boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 4)],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final List<String> userAnswers = _dndLists.length > 1
                ? _dndLists[1].children.map((item) => ((item.child as ListTile).title as Text).data!).toList()
                : [];
            bool isCorrect = const ListEquality().equals(userAnswers, question.correctAnswers);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isCorrect ? 'Acorde correto!' : 'Tente novamente!'),
                backgroundColor: isCorrect ? Colors.green : AppColors.primary,
              ),
            );

            if (isCorrect) {
              _nextStep();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('VERIFICAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
        ),
      ],
    );
  }

  Widget _buildNoteTile(String noteName) {
    return ListTile(
      tileColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(noteName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      leading: const Icon(Icons.music_note, color: AppColors.accent),
    );
  }

  Color _getButtonColor(String option, String correctAnswer) {
    if (_selectedAnswer == null) return AppColors.card;
    if (option == _selectedAnswer) return _isCorrect! ? Colors.green : AppColors.primary;
    if (option == correctAnswer) return Colors.green;
    return AppColors.card;
  }
}