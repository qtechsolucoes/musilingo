// lib/features/lesson/data/models/question_model.dart

import 'package:musilingo/features/lesson/data/models/drag_drop_question_model.dart';
import 'package:musilingo/features/lesson/data/models/ear_training_question_model.dart';
import 'package:musilingo/features/lesson/data/models/multiple_choice_question_model.dart';

// 1. ADICIONADO O TIPO 'multipleChoice'
enum QuestionType {
  multipleChoice,
  dragAndDrop,
  earTraining,
}

abstract class Question {
  final int id;
  final int lessonId;
  final QuestionType type;

  Question({required this.id, required this.lessonId, required this.type});

  factory Question.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String;
    final type = QuestionType.values.firstWhere(
      (e) => e.toString() == 'QuestionType.$typeString',
      orElse: () =>
          throw Exception('TIPO DE QUESTÃO DESCONHECIDO: $typeString'),
    );

    // 2. ADICIONADO O 'case' PARA O NOVO TIPO
    switch (type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestion.fromMap(map);
      case QuestionType.dragAndDrop:
        return DragAndDropQuestion.fromMap(map);
      case QuestionType.earTraining:
        return EarTrainingQuestion.fromMap(map);
    }
  }
}
