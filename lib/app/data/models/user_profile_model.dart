// lib/app/data/models/user_profile_model.dart

class UserProfile {
  final String id;
  final String fullName;
  String? avatarUrl;
  int points;
  int lives;
  int correctAnswers;
  int wrongAnswers;

  UserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.points,
    required this.lives,
    required this.correctAnswers,
    required this.wrongAnswers,
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
    );
  }
}
