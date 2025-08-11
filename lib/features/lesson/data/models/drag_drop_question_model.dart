// lib/features/lesson/data/models/drag_drop_question_model.dart

import 'package:musilingo/features/lesson/data/models/question_model.dart';

class DragAndDropQuestion extends Question {
  final List<String> items;
  final List<String> correctOrder;

  DragAndDropQuestion({
    required super.id,
    required super.lessonId,
    required this.items,
    required this.correctOrder,
  }) : super(type: QuestionType.dragAndDrop);

  factory DragAndDropQuestion.fromMap(Map<String, dynamic> map) {
    return DragAndDropQuestion(
      id: map['id'],
      lessonId: map['lesson_id'],
      items: List<String>.from(map['items']),
      correctOrder: List<String>.from(map['correct_order']),
    );
  }
}
