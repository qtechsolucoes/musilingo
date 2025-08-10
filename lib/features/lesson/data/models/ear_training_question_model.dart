// lib/features/lesson/data/models/ear_training_question_model.dart

class EarTrainingQuestion {
  final String statement;
  // No futuro, este assetPath apontará para um arquivo de áudio (ex: 'assets/audio/terca_maior.mp3')
  final String audioAssetPath;
  final List<String> options;
  final String correctAnswer;

  EarTrainingQuestion({
    required this.statement,
    required this.audioAssetPath,
    required this.options,
    required this.correctAnswer,
  });
}
