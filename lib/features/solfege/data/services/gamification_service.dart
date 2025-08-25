import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solfege_exercise.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Sistema de pontos
  static const int perfectScore = 100;
  static const int goodScore = 70;
  static const int passScore = 50;

  // Multiplicadores
  static const double streakMultiplier = 1.1;
  static const double difficultyMultiplier = 1.5;

  // Achievements
  final List<Achievement> achievements = [
    Achievement(
      id: 'first_perfect',
      name: 'Primeira Perfeição',
      description: 'Complete um exercício com 100% de acerto',
      icon: '🌟',
      xpReward: 50,
    ),
    Achievement(
      id: 'streak_5',
      name: 'Sequência de 5',
      description: 'Complete 5 exercícios seguidos',
      icon: '🔥',
      xpReward: 100,
    ),
    Achievement(
      id: 'pitch_master',
      name: 'Mestre da Afinação',
      description: '10 exercícios com altura perfeita',
      icon: '🎵',
      xpReward: 200,
    ),
    Achievement(
      id: 'rhythm_king',
      name: 'Rei do Ritmo',
      description: '10 exercícios com duração perfeita',
      icon: '⏱️',
      xpReward: 200,
    ),
    Achievement(
      id: 'solfege_expert',
      name: 'Expert em Solfejo',
      description: 'Complete 50 exercícios',
      icon: '🎓',
      xpReward: 500,
    ),
  ];

  Future<UserStats> getUserStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    final response = await _supabase
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .single();

    return UserStats.fromJson(response);
  }

  Future<int> calculateScore(SolfegeResult result, String difficulty) async {
    int baseScore = 0;

    // Pontuação base
    if (result.overallAccuracy == 1.0) {
      baseScore = perfectScore;
    } else if (result.overallAccuracy >= 0.7) {
      baseScore = (result.overallAccuracy * goodScore).round();
    } else if (result.overallAccuracy >= 0.5) {
      baseScore = (result.overallAccuracy * passScore).round();
    } else {
      baseScore = -(50 - (result.overallAccuracy * 100).round());
    }

    // Aplicar multiplicador de dificuldade
    switch (difficulty) {
      case 'basico':
        baseScore = (baseScore * 1.0).round();
        break;
      case 'intermediario':
        baseScore = (baseScore * 1.3).round();
        break;
      case 'avancado':
        baseScore = (baseScore * 1.6).round();
        break;
      case 'expert':
        baseScore = (baseScore * 2.0).round();
        break;
    }

    // Aplicar bônus de sequência
    final stats = await getUserStats();
    if (stats.currentStreak > 0) {
      baseScore = (baseScore * (1 + stats.currentStreak * 0.02)).round();
    }

    return baseScore;
  }

  Future<void> saveExerciseResult(
    String exerciseId,
    SolfegeResult result,
    String difficulty,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final score = await calculateScore(result, difficulty);

    // Salvar resultado
    await _supabase.from('exercise_results').insert({
      'user_id': userId,
      'exercise_id': exerciseId,
      'score': score,
      'accuracy': result.overallAccuracy,
      'correct_pitch': result.correctPitch,
      'correct_duration': result.correctDuration,
      'correct_name': result.correctName,
      'total_notes': result.totalNotes,
      'completed_at': DateTime.now().toIso8601String(),
    });

    // Atualizar estatísticas do usuário
    await _updateUserStats(userId, score, result);

    // Verificar achievements
    await _checkAchievements(userId, result);
  }

  Future<void> _updateUserStats(
    String userId,
    int score,
    SolfegeResult result,
  ) async {
    final stats = await getUserStats();

    // Atualizar XP e nível
    final newXp = stats.totalXp + score.abs();
    final newLevel = _calculateLevel(newXp);

    // Atualizar sequência
    final isSuccess = result.overallAccuracy >= 0.5;
    final newStreak = isSuccess ? stats.currentStreak + 1 : 0;
    final bestStreak =
        newStreak > stats.bestStreak ? newStreak : stats.bestStreak;

    // Atualizar estatísticas
    await _supabase.from('user_stats').upsert({
      'user_id': userId,
      'total_xp': newXp,
      'level': newLevel,
      'current_streak': newStreak,
      'best_streak': bestStreak,
      'total_exercises': stats.totalExercises + 1,
      'perfect_exercises':
          stats.perfectExercises + (result.overallAccuracy == 1.0 ? 1 : 0),
      'average_accuracy': ((stats.averageAccuracy * stats.totalExercises) +
              result.overallAccuracy) /
          (stats.totalExercises + 1),
      'last_practice': DateTime.now().toIso8601String(),
    });
  }

  int _calculateLevel(int xp) {
    // Sistema de níveis exponencial
    return (math.sqrt(xp / 100)).floor() + 1;
  }

  Future<void> _checkAchievements(String userId, SolfegeResult result) async {
    final stats = await getUserStats();
    final userAchievements = await _getUserAchievements(userId);

    for (final achievement in achievements) {
      if (userAchievements.contains(achievement.id)) continue;

      bool earned = false;

      switch (achievement.id) {
        case 'first_perfect':
          earned = result.overallAccuracy == 1.0;
          break;
        case 'streak_5':
          earned = stats.currentStreak >= 5;
          break;
        case 'pitch_master':
          earned = await _checkPitchMaster(userId);
          break;
        case 'rhythm_king':
          earned = await _checkRhythmKing(userId);
          break;
        case 'solfege_expert':
          earned = stats.totalExercises >= 50;
          break;
      }

      if (earned) {
        await _grantAchievement(userId, achievement);
      }
    }
  }

  Future<bool> _checkPitchMaster(String userId) async {
    final results = await _supabase
        .from('exercise_results')
        .select('correct_pitch, total_notes')
        .eq('user_id', userId)
        .order('completed_at', ascending: false)
        .limit(10);

    int perfectPitchCount = 0;
    for (final result in results) {
      if (result['correct_pitch'] == result['total_notes']) {
        perfectPitchCount++;
      }
    }

    return perfectPitchCount >= 10;
  }

  Future<bool> _checkRhythmKing(String userId) async {
    final results = await _supabase
        .from('exercise_results')
        .select('correct_duration, total_notes')
        .eq('user_id', userId)
        .order('completed_at', ascending: false)
        .limit(10);

    int perfectRhythmCount = 0;
    for (final result in results) {
      if (result['correct_duration'] == result['total_notes']) {
        perfectRhythmCount++;
      }
    }

    return perfectRhythmCount >= 10;
  }

  Future<List<String>> _getUserAchievements(String userId) async {
    final results = await _supabase
        .from('user_achievements')
        .select('achievement_id')
        .eq('user_id', userId);

    return results.map<String>((r) => r['achievement_id'] as String).toList();
  }

  Future<void> _grantAchievement(String userId, Achievement achievement) async {
    await _supabase.from('user_achievements').insert({
      'user_id': userId,
      'achievement_id': achievement.id,
      'earned_at': DateTime.now().toIso8601String(),
    });

    // Adicionar XP de recompensa
    final stats = await getUserStats();
    await _supabase.from('user_stats').update({
      'total_xp': stats.totalXp + achievement.xpReward,
    }).eq('user_id', userId);
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    String period = 'week',
    int limit = 10,
  }) async {
    DateTime startDate;

    switch (period) {
      case 'day':
        startDate = DateTime.now().subtract(const Duration(days: 1));
        break;
      case 'week':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      default:
        startDate = DateTime(2000); // All time
    }

    final results = await _supabase
        .from('leaderboard_view')
        .select()
        .gte('last_practice', startDate.toIso8601String())
        .order('total_xp', ascending: false)
        .limit(limit);

    return results
        .map<LeaderboardEntry>((r) => LeaderboardEntry.fromJson(r))
        .toList();
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
  });
}

class UserStats {
  final String userId;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int bestStreak;
  final int totalExercises;
  final int perfectExercises;
  final double averageAccuracy;
  final DateTime? lastPractice;

  UserStats({
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalExercises,
    required this.perfectExercises,
    required this.averageAccuracy,
    this.lastPractice,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'],
      totalXp: json['total_xp'] ?? 0,
      level: json['level'] ?? 1,
      currentStreak: json['current_streak'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      totalExercises: json['total_exercises'] ?? 0,
      perfectExercises: json['perfect_exercises'] ?? 0,
      averageAccuracy: (json['average_accuracy'] ?? 0.0).toDouble(),
      lastPractice: json['last_practice'] != null
          ? DateTime.parse(json['last_practice'])
          : null,
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      totalXp: json['total_xp'],
      level: json['level'],
      rank: json['rank'] ?? 0,
    );
  }
}
