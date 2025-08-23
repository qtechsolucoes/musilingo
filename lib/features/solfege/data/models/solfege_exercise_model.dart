// lib/features/solfege/data/models/solfege_exercise_model.dart

// Classe que representa uma única nota na sequência do exercício
class SolfegeNote {
  final String pitch; // Ex: "C4", "F#5"
  final String duration; // Ex: "quarter", "half"
  final String lyric; // Ex: "Dó", "Sol"

  SolfegeNote({
    required this.pitch,
    required this.duration,
    required this.lyric,
  });

  // Construtor factory para criar uma instância a partir de um mapa (JSON)
  factory SolfegeNote.fromMap(Map<String, dynamic> map) {
    return SolfegeNote(
      pitch: map['note'] as String,
      duration: map['duration'] as String,
      lyric: map['lyric'] as String,
    );
  }

  get pitchInHz => null;
}

// Classe que representa o exercício de solfejo completo
class SolfegeExercise {
  final int id;
  final String title;
  final String difficultyLevel;
  final int difficultyValue;
  final String clef; // <-- Adicionado o campo que faltava
  final String keySignature;
  final String timeSignature;
  final int tempo;
  final List<SolfegeNote> noteSequence;

  SolfegeExercise({
    required this.id,
    required this.title,
    required this.difficultyLevel,
    required this.difficultyValue,
    required this.clef, // <-- Adicionado o campo que faltava
    required this.keySignature,
    required this.timeSignature,
    required this.tempo,
    required this.noteSequence,
  });

  // Construtor factory para criar um exercício a partir do JSON retornado pelo Supabase
  factory SolfegeExercise.fromJson(Map<String, dynamic> json) {
    // O Supabase já decodifica o JSONB para uma List<dynamic>
    final List<dynamic> notesJson = json['note_sequence'];

    final List<SolfegeNote> notes = notesJson
        .map((noteMap) => SolfegeNote.fromMap(noteMap as Map<String, dynamic>))
        .toList();

    return SolfegeExercise(
      id: json['id'] as int,
      title: json['title'] as String,
      difficultyLevel: json['difficulty_level'] as String,
      difficultyValue: json['difficulty_value'] as int,
      clef: json['clef'] as String, // <-- Adicionado o campo que faltava
      keySignature: json['key_signature'] as String,
      timeSignature: json['time_signature'] as String,
      tempo: json['tempo'] as int,
      noteSequence: notes,
    );
  }
}
