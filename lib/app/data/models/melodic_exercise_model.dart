// lib/app/data/models/melodic_exercise_model.dart

class MelodicExercise {
  final int id;
  final String title;
  final int difficulty;
  final String clef;
  final String keySignature;
  final String timeSignature;
  final String referenceNote;
  final List<String> possibleNotes;
  final List<String> possibleFigures;
  final List<String> correctSequence;
  final String audioUrl;
  final String referenceNoteAudioUrl;

  MelodicExercise({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.clef,
    required this.keySignature,
    required this.timeSignature,
    required this.referenceNote,
    required this.possibleNotes,
    required this.possibleFigures,
    required this.correctSequence,
    required this.audioUrl,
    required this.referenceNoteAudioUrl,
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
      possibleNotes: List<String>.from(map['possible_notes'] ?? []),
      possibleFigures: List<String>.from(map['possible_figures'] ?? []),
      correctSequence: List<String>.from(map['correct_sequence'] ?? []),
      audioUrl: map['audio_url'] ?? '',
      referenceNoteAudioUrl: map['reference_note_audio_url'] ?? '',
    );
  }

  static fromJson(e) {}
}
