// lib/app/services/database_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/data/models/weekly_xp_model.dart'; // <-- NOVO IMPORT
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  List<Module>? _cachedModules;
  DateTime? _lastFetchTime;

  Future<List<Module>> getModulesAndLessons() async {
    if (_cachedModules != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(minutes: 10)) {
      debugPrint("CACHE HIT: Retornando módulos da memória.");
      return _cachedModules!;
    }

    debugPrint("CACHE MISS: Buscando módulos do Supabase.");
    final response = await supabase
        .from('modules')
        .select('*, lessons(*)')
        .order('id', ascending: true);

    final modules =
        (response as List).map((data) => Module.fromMap(data)).toList();

    _cachedModules = modules;
    _lastFetchTime = DateTime.now();

    return modules;
  }

  Future<Set<int>> getCompletedLessonIds(String userId) async {
    final response = await supabase
        .from('completed_lessons')
        .select('lesson_id')
        .eq('user_id', userId);
    return (response as List).map((data) => data['lesson_id'] as int).toSet();
  }

  Future<List<LessonStep>> getStepsForLesson(int lessonId) async {
    final response = await supabase
        .from('lesson_steps')
        .select('*')
        .eq('lesson_id', lessonId)
        .order('step_index', ascending: true);
    return (response as List).map((data) => LessonStep.fromMap(data)).toList();
  }

  Future<void> markLessonAsCompleted(String userId, int lessonId) async {
    _cachedModules = null;
    _lastFetchTime = null;

    await supabase.from('completed_lessons').insert({
      'user_id': userId,
      'lesson_id': lessonId,
    });
  }

  Future<UserProfile?> getProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
    if (response == null || response.isEmpty) {
      return null;
    }
    return UserProfile.fromMap(response);
  }

  Future<UserProfile> createProfileOnLogin(User user) async {
    final response = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null && response.isNotEmpty) {
      return UserProfile.fromMap(response);
    } else {
      final newProfileData = {
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'Músico Anônimo',
        'avatar_url': user.userMetadata?['avatar_url'],
        'league':
            'Bronze', // Garante que novos utilizadores começam na liga Bronze
      };
      await supabase.from('profiles').insert(newProfileData);

      return UserProfile.fromMap(newProfileData);
    }
  }

  // ATUALIZADO para incluir o campo 'league'
  Future<void> updateStats({
    required String userId,
    int? points,
    int? lives,
    int? correctAnswers,
    int? wrongAnswers,
    int? currentStreak,
    String? lastPracticeDate,
    String? league, // <-- NOVO PARÂMETRO
  }) async {
    final updates = <String, dynamic>{};
    if (points != null) updates['points'] = points;
    if (lives != null) updates['lives'] = lives;
    if (correctAnswers != null) updates['correct_answers'] = correctAnswers;
    if (wrongAnswers != null) updates['wrong_answers'] = wrongAnswers;
    if (currentStreak != null) updates['current_streak'] = currentStreak;
    if (lastPracticeDate != null) {
      updates['last_practice_date'] = lastPracticeDate;
    }
    if (league != null) updates['league'] = league; // <-- NOVA LINHA

    if (updates.isNotEmpty) {
      await supabase.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<String> uploadAvatar(String userId, File image) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bucket = supabase.storage.from('lesson_assets');
    await bucket.upload(fileName, image);
    final publicUrl = bucket.getPublicUrl(fileName);
    await supabase
        .from('profiles')
        .update({'avatar_url': publicUrl}).eq('id', userId);
    return publicUrl;
  }

  Future<List<MelodicExercise>> getMelodicExercises() async {
    final response = await supabase
        .from('practice_melodies')
        .select('*')
        .order('difficulty', ascending: true)
        .order('id', ascending: true);

    return (response as List)
        .map((data) => MelodicExercise.fromMap(data))
        .toList();
  }

  // --- NOVAS FUNÇÕES PARA AS LIGAS ---

  /// Adiciona pontos ao XP semanal de um utilizador.
  /// Usa um procedimento da base de dados (RPC) para garantir que a operação é atómica.
  Future<void> upsertWeeklyXp(String userId, int pointsToAdd) async {
    await supabase.rpc('upsert_weekly_xp', params: {
      'p_user_id': userId,
      'p_xp_to_add': pointsToAdd,
    });
  }

  /// Vai buscar o ranking da liga de um determinado utilizador.
  Future<List<WeeklyXp>> getLeagueLeaderboard(String userLeague) async {
    // Esta query é mais complexa:
    // 1. Seleciona todos os campos da tabela 'weekly_xp'
    // 2. Junta (`inner join`) com a tabela 'profiles' para obter os dados do perfil
    // 3. Filtra para trazer apenas os utilizadores da mesma liga que o jogador atual
    // 4. Ordena por XP descendente (quem tem mais pontos aparece primeiro)
    // 5. Limita o resultado aos 30 melhores para manter os grupos pequenos
    final response = await supabase
        .from('weekly_xp')
        .select(
            '*, profiles!inner(*)') // !inner garante que só vêm resultados com perfil correspondente
        .eq('profiles.league', userLeague)
        .order('xp', ascending: false)
        .limit(30);

    return (response as List).map((data) => WeeklyXp.fromMap(data)).toList();
  }
}
