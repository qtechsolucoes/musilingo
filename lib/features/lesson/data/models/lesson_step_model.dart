// lib/features/lesson/data/models/lesson_step_model.dart
import 'package:musilingo/features/lesson/data/models/drag_drop_question_model.dart';
import 'package:musilingo/features/lesson/data/models/ear_training_question_model.dart';
import 'package:musilingo/features/lesson/data/models/question_model.dart';

// Adicionamos o novo tipo de passo
enum LessonStepType { theory, question, earTraining, dragAndDrop }

abstract class LessonStep {
  final LessonStepType type;
  LessonStep(this.type);
}

class TheoryStep extends LessonStep {
  final String title;
  final String content;
  final String? imageAsset;

  TheoryStep({
    required this.title,
    required this.content,
    this.imageAsset,
  }) : super(LessonStepType.theory);
}

class QuestionStep extends LessonStep {
  final Question question;
  QuestionStep(this.question) : super(LessonStepType.question);
}

class EarTrainingStep extends LessonStep {
  final EarTrainingQuestion question;
  EarTrainingStep(this.question) : super(LessonStepType.earTraining);
}

// Nova classe para o passo de arrastar e soltar
class DragAndDropStep extends LessonStep {
  final DragAndDropQuestion question;
  DragAndDropStep(this.question) : super(LessonStepType.dragAndDrop);
}
