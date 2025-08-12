// lib/features/lesson/data/models/multiple_choice_question_model.dart

import 'package:musilingo/features/lesson/data/models/question_model.dart';

class MultipleChoiceQuestion extends Question {
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  MultipleChoiceQuestion({
    required super.id,
    required super.lessonId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  }) : super(type: QuestionType.multipleChoice);

  factory MultipleChoiceQuestion.fromMap(Map<String, dynamic> map) {
    return MultipleChoiceQuestion(
      id: map['id'],
      lessonId: map['lesson_id'],
      questionText: map['question_text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correct_answer'] ?? '',
    );
  }
}
