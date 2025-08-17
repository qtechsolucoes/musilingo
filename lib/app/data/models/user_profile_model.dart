// lib/app/data/models/user_profile_model.dart

class UserProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final int points;
  final int lives;
  final int correctAnswers;
  final int wrongAnswers;
  final int currentStreak;
  final String? lastPracticeDate;
  final String league;

  UserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.points = 0,
    this.lives = 5,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.currentStreak = 0,
    this.lastPracticeDate,
    required this.league,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      points: map['points'] as int? ?? 0,
      lives: map['lives'] as int? ?? 5,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      wrongAnswers: map['wrong_answers'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
      lastPracticeDate: map['last_practice_date'] as String?,
      league: map['league'] as String? ?? 'Bronze',
    );
  }

  // --- MÉTODO COPYWITH ADICIONADO E CORRIGIDO ---
  UserProfile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    int? points,
    int? lives,
    int? correctAnswers,
    int? wrongAnswers,
    int? currentStreak,
    String? lastPracticeDate,
    String? league,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      lives: lives ?? this.lives,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      league: league ?? this.league,
    );
  }
}
