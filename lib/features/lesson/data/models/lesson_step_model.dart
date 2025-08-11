// lib/features/lesson/data/models/lesson_step_model.dart
import 'package:musilingo/features/lesson/data/models/drag_drop_question_model.dart';
import 'package:musilingo/features/lesson/data/models/ear_training_question_model.dart';
import 'package:musilingo/features/lesson/data/models/question_model.dart';

enum LessonStepType { theory, question, earTraining, dragAndDrop }

abstract class LessonStep {
  final LessonStepType type;
  LessonStep(this.type);

  // Factory constructor para criar o tipo de passo correto a partir dos dados do Supabase.
  factory LessonStep.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'];
    final content = map['content'] as Map<String, dynamic>;

    switch (typeString) {
      case 'theory':
        return TheoryStep.fromContent(content);
      case 'question':
        return QuestionStep.fromContent(content);
      case 'earTraining':
        return EarTrainingStep.fromContent(content);
      case 'dragAndDrop':
        return DragAndDropStep.fromContent(content);
      default:
        throw Exception('Tipo de passo desconhecido: $typeString');
    }
  }
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

  // Construtor para criar a partir do JSON 'content' do Supabase.
  factory TheoryStep.fromContent(Map<String, dynamic> content) {
    return TheoryStep(
      title: content['title'],
      content: content['text'], // Note a mudança de 'content' para 'text'
      imageAsset: content['imageAsset'],
    );
  }
}

class QuestionStep extends LessonStep {
  final Question question;
  QuestionStep(this.question) : super(LessonStepType.question);

  // Construtor para criar a partir do JSON 'content' do Supabase.
  factory QuestionStep.fromContent(Map<String, dynamic> content) {
    return QuestionStep(
      Question(
        statement: content['statement'],
        imageAsset: content['imageAsset'],
        options: List<String>.from(content['options']),
        correctAnswer: content['correctAnswer'],
      ),
    );
  }
}

class EarTrainingStep extends LessonStep {
  final EarTrainingQuestion question;
  EarTrainingStep(this.question) : super(LessonStepType.earTraining);

  // Construtor para criar a partir do JSON 'content' do Supabase.
  factory EarTrainingStep.fromContent(Map<String, dynamic> content) {
    return EarTrainingStep(
      EarTrainingQuestion(
        statement: content['statement'],
        audioAssetPath: content['audioAssetPath'],
        options: List<String>.from(content['options']),
        correctAnswer: content['correctAnswer'],
      ),
    );
  }
}

class DragAndDropStep extends LessonStep {
  final DragAndDropQuestion question;
  DragAndDropStep(this.question) : super(LessonStepType.dragAndDrop);

  // Construtor para criar a partir do JSON 'content' do Supabase.
  factory DragAndDropStep.fromContent(Map<String, dynamic> content) {
    return DragAndDropStep(
      DragAndDropQuestion(
        statement: content['statement'],
        // Precisamos converter a lista de opções em DraggableNote
        options: (content['options'] as List<dynamic>).map((noteName) => DraggableNote(name: noteName.toString())).toList(),
        correctAnswers: List<String>.from(content['correctAnswers']),
      ),
    );
  }
}