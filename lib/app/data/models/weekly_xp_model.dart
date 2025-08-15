// lib/app/data/models/weekly_xp_model.dart

import 'package:musilingo/app/data/models/user_profile_model.dart';

class WeeklyXp {
  final String userId;
  final int xp;
  final DateTime updatedAt;
  // Opcional: Para guardar os detalhes do perfil ao fazer o ranking
  final UserProfile? userProfile;

  WeeklyXp({
    required this.userId,
    required this.xp,
    required this.updatedAt,
    this.userProfile,
  });

  factory WeeklyXp.fromMap(Map<String, dynamic> map) {
    return WeeklyXp(
      userId: map['user_id'],
      xp: map['xp'] ?? 0,
      updatedAt: DateTime.parse(map['updated_at']),
      // Se a query vier com os dados do perfil (JOIN), cria o objeto UserProfile
      userProfile: map.containsKey('profiles') && map['profiles'] != null
          ? UserProfile.fromMap(map['profiles'])
          : null,
    );
  }
}
