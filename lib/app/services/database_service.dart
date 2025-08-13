// lib/app/services/database_service.dart

import 'dart:io';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  // --- MÉTODOS DE LIÇÃO ---
  Future<List<Module>> getModulesAndLessons() async {
    final response = await supabase
        .from('modules')
        .select('*, lessons(*)')
        .order('id', ascending: true);
    return (response as List).map((data) => Module.fromMap(data)).toList();
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
    await supabase.from('completed_lessons').insert({
      'user_id': userId,
      'lesson_id': lessonId,
    });
  }

  // --- MÉTODOS DE PERFIL ---
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

  // --- ALTERAÇÃO INÍCIO ---
  // Nova função para garantir que um perfil exista após o login.
  Future<UserProfile> createProfileOnLogin(User user) async {
    // 1. Tenta buscar o perfil existente.
    final response = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    // 2. Se o perfil já existe, retorna-o.
    if (response != null && response.isNotEmpty) {
      return UserProfile.fromMap(response);
    }
    // 3. Se não existe, cria um novo perfil.
    else {
      final newProfileData = {
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'Músico Anônimo',
        'avatar_url': user.userMetadata?['avatar_url'],
      };
      // Insere o novo perfil no banco de dados
      await supabase.from('profiles').insert(newProfileData);

      // Retorna o perfil recém-criado a partir dos mesmos dados
      return UserProfile.fromMap(newProfileData);
    }
  }
  // --- ALTERAÇÃO FIM ---

  Future<void> updateStats({
    required String userId,
    int? points,
    int? lives,
    int? correctAnswers,
    int? wrongAnswers,
  }) async {
    final updates = <String, dynamic>{};
    if (points != null) updates['points'] = points;
    if (lives != null) updates['lives'] = lives;
    if (correctAnswers != null) updates['correct_answers'] = correctAnswers;
    if (wrongAnswers != null) updates['wrong_answers'] = wrongAnswers;

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
}
