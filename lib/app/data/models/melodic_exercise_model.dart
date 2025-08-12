// lib/app/data/models/melodic_exercise_model.dart

class MelodicExercise {
  final int id;
  final String title;
  final int difficulty;
  final String clef;
  final String keySignature;
  final String timeSignature;
  final String referenceNote;
  final String musicXml;

  // --- ALTERAÇÃO INÍCIO ---
  // A sequência correta de notas volta a fazer parte do modelo.
  // Ela será usada como gabarito para a verificação.
  final List<String> correctSequence;
  // --- ALTERAÇÃO FIM ---

  MelodicExercise({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.clef,
    required this.keySignature,
    required this.timeSignature,
    required this.referenceNote,
    required this.musicXml,
    // --- ALTERAÇÃO INÍCIO ---
    required this.correctSequence,
    // --- ALTERAÇÃO FIM ---
  });

  factory MelodicExercise.fromMap(Map<String, dynamic> map) {
    return MelodicExercise(
      id: map['id'],
      title: map['title'] ?? '',
      difficulty: map['difficulty'] ?? 1,
      clef: map['clef'] ?? 'treble',
      keySignature: map['key_signature'] ?? 'C',
      timeSignature: map['time_signature'] ?? '4/4',
      referenceNote: map['reference_note'] ?? 'C4',
      musicXml: map['music_xml'] ?? '',
      // --- ALTERAÇÃO INÍCIO ---
      // Lendo a sequência do banco de dados novamente.
      correctSequence: List<String>.from(map['correct_sequence'] ?? []),
      // --- ALTERAÇÃO FIM ---
    );
  }
}
