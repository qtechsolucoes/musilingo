// lib/features/lesson/presentation/view/lesson_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/features/lesson/data/models/question_model.dart';
import 'package:musilingo/features/lesson/data/models/drag_drop_question_model.dart';
import 'package:musilingo/features/lesson/data/models/ear_training_question_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/main.dart';
import 'package:just_audio/just_audio.dart';
// A importação de 'drag_and_drop_lists' foi removida daqui.

class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<List<Question>> _questionsFuture;
  int _currentQuestionIndex = 0;
  bool _isCorrect = false;
  bool _showFeedback = false;
  final DatabaseService _databaseService = DatabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _questionsFuture = _databaseService.getQuestionsForLesson(widget.lesson.id);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onAnswerSubmitted(bool isCorrect) {
    setState(() {
      _isCorrect = isCorrect;
      _showFeedback = true;
    });
  }

  void _nextQuestion(int totalQuestions) async {
    if (_currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showFeedback = false;
      });
    } else {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await _databaseService.markLessonAsCompleted(userId, widget.lesson.id);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
                child: Text(
                    'Erro: ${snapshot.error ?? "Não foi possível carregar as perguntas."}'));
          }

          final questions = snapshot.data!;
          final currentQuestion = questions[_currentQuestionIndex];
          final progress = (_currentQuestionIndex + 1) / questions.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.completed),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildQuestionWidget(currentQuestion),
                ),
              ),
              if (_showFeedback)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _isCorrect
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isCorrect ? 'Correto!' : 'Tente novamente.',
                        style: TextStyle(
                          color: _isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _nextQuestion(questions.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isCorrect ? Colors.green : AppColors.primary,
                        ),
                        child: Text(_currentQuestionIndex < questions.length - 1
                            ? 'Continuar'
                            : 'Finalizar'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionWidget(Question question) {
    switch (question.type) {
      case QuestionType.dragAndDrop:
        return _buildDragAndDropQuestion(question as DragAndDropQuestion);
      case QuestionType.earTraining:
        return _buildEarTrainingQuestion(question as EarTrainingQuestion);
    }
  }

  Widget _buildDragAndDropQuestion(DragAndDropQuestion question) {
    return const Center(child: Text("Pergunta de Arrastar e Soltar"));
  }

  Widget _buildEarTrainingQuestion(EarTrainingQuestion question) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question.text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        IconButton(
          icon: const Icon(Icons.play_circle_fill),
          iconSize: 64,
          color: AppColors.primary,
          onPressed: () async {
            try {
              if (question.audioUrl.startsWith('http')) {
                await _audioPlayer.setUrl(question.audioUrl);
              } else {
                await _audioPlayer.setAsset(question.audioUrl);
              }
              _audioPlayer.play();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao tocar o áudio.')),
                );
              }
            }
          },
        ),
        const SizedBox(height: 40),
        ...question.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () =>
                  _onAnswerSubmitted(option == question.correctAnswer),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(option),
            ),
          );
        }),
      ],
    );
  }
}
