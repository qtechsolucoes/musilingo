// lib/features/lesson/data/models/drag_drop_question_model.dart

class DraggableNote {
  final String name;
  DraggableNote({required this.name});
}

class DragAndDropQuestion {
  final String statement;
  final List<String> correctAnswers; // As notas corretas em ordem
  final List<DraggableNote> options; // O "banco" de notas para arrastar

  DragAndDropQuestion({
    required this.statement,
    required this.correctAnswers,
    required this.options,
  });
}
