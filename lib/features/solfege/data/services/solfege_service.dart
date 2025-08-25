import 'dart:convert';

class SolfegeExercise {
  final String id;
  final String title;
  final String difficultyLevel;
  final int difficultyValue;
  final String keySignature;
  final String timeSignature;
  final int tempo;
  final List<NoteInfo> noteSequence;
  final DateTime createdAt;

  SolfegeExercise({
    required this.id,
    required this.title,
    required this.difficultyLevel,
    required this.difficultyValue,
    required this.keySignature,
    required this.timeSignature,
    required this.tempo,
    required this.noteSequence,
    required this.createdAt,
  });

  factory SolfegeExercise.fromJson(Map<String, dynamic> json) {
    return SolfegeExercise(
      id: json['id'],
      title: json['title'],
      difficultyLevel: json['difficulty_level'],
      difficultyValue: json['difficulty_value'],
      keySignature: json['key_signature'],
      timeSignature: json['time_signature'],
      tempo: json['tempo'],
      noteSequence: (jsonDecode(json['note_sequence']) as List)
          .map((e) => NoteInfo.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NoteInfo {
  final String note;
  final String lyric;
  final String duration;

  // Estados de execução
  bool isActive = false;
  bool isCorrect = false;
  bool hasBeenPlayed = false;

  // Resultados da análise
  bool? pitchCorrect;
  bool? durationCorrect;
  bool? nameCorrect;

  NoteInfo({
    required this.note,
    required this.lyric,
    required this.duration,
  });

  factory NoteInfo.fromJson(Map<String, dynamic> json) {
    return NoteInfo(
      note: json['note'],
      lyric: json['lyric'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() => {
        'note': note,
        'lyric': lyric,
        'duration': duration,
      };

  double get frequency {
    final frequencies = {
      'C4': 261.63,
      'D4': 293.66,
      'E4': 329.63,
      'F4': 349.23,
      'G4': 392.00,
      'A4': 440.00,
      'B4': 493.88,
      'C5': 523.25,
      'C#4': 277.18,
      'D#4': 311.13,
      'F#4': 369.99,
      'G#4': 415.30,
      'A#4': 466.16,
    };
    return frequencies[note] ?? 440.0;
  }

  double getDurationInSeconds(int tempo) {
    final beatDuration = 60.0 / tempo;
    final durations = {
      'whole': beatDuration * 4,
      'half': beatDuration * 2,
      'quarter': beatDuration,
      'eighth': beatDuration / 2,
      'sixteenth': beatDuration / 4,
    };
    return durations[duration] ?? beatDuration;
  }
}

class SolfegeResult {
  final int totalNotes;
  final int correctPitch;
  final int correctDuration;
  final int correctName;
  final double overallAccuracy;
  final int score;
  final List<NoteResult> noteResults;

  SolfegeResult({
    required this.totalNotes,
    required this.correctPitch,
    required this.correctDuration,
    required this.correctName,
    required this.overallAccuracy,
    required this.score,
    required this.noteResults,
  });
}

class NoteResult {
  final String note;
  final String expectedName;
  final String? detectedName;
  final double expectedFrequency;
  final double? detectedFrequency;
  final double expectedDuration;
  final double? detectedDuration;
  final bool pitchCorrect;
  final bool durationCorrect;
  final bool nameCorrect;

  NoteResult({
    required this.note,
    required this.expectedName,
    this.detectedName,
    required this.expectedFrequency,
    this.detectedFrequency,
    required this.expectedDuration,
    this.detectedDuration,
    required this.pitchCorrect,
    required this.durationCorrect,
    required this.nameCorrect,
  });
}
