// lib/features/lesson/data/models/ear_training_question_model.dart

import 'package:musilingo/features/lesson/data/models/question_model.dart';

class EarTrainingQuestion extends Question {
  final String text; // Propriedade 'text' adicionada
  final String audioUrl; // Propriedade 'audioUrl' adicionada
  final List<String> options;
  final String correctAnswer;

  EarTrainingQuestion({
    required super.id,
    required super.lessonId,
    required this.text,
    required this.audioUrl,
    required this.options,
    required this.correctAnswer,
  }) : super(type: QuestionType.earTraining);

  factory EarTrainingQuestion.fromMap(Map<String, dynamic> map) {
    return EarTrainingQuestion(
      id: map['id'],
      lessonId: map['lesson_id'],
      text: map['text'],
      audioUrl: map['audio_url'],
      options: List<String>.from(map['options']),
      correctAnswer: map['correct_answer'],
    );
  }
}
