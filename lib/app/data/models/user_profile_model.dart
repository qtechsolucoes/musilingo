// lib/app/data/models/user_profile_model.dart

class UserProfile {
  final String id;
  final String fullName;
  String? avatarUrl;
  int points;
  int lives;
  int correctAnswers;
  int wrongAnswers;
  int currentStreak;
  DateTime? lastPracticeDate;
  // NOVO CAMPO PARA A LIGA
  String league;

  UserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.points,
    required this.lives,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.currentStreak,
    this.lastPracticeDate,
    required this.league,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      fullName: map['full_name'] ?? 'Músico',
      avatarUrl: map['avatar_url'],
      points: map['points'] ?? 0,
      lives: map['lives'] ?? 5,
      correctAnswers: map['correct_answers'] ?? 0,
      wrongAnswers: map['wrong_answers'] ?? 0,
      currentStreak: map['current_streak'] ?? 0,
      lastPracticeDate: map['last_practice_date'] != null
          ? DateTime.parse(map['last_practice_date'])
          : null,
      // Lendo o novo campo do mapa
      league: map['league'] ?? 'Bronze',
    );
  }
}
