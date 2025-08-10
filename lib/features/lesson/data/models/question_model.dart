// lib/features/lesson/data/models/question_model.dart

class Question {
  final String statement;
  final String? imageAsset; // Campo para o caminho da imagem (opcional)
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.statement,
    this.imageAsset, // Adicionado ao construtor
    required this.options,
    required this.correctAnswer,
  });
}
