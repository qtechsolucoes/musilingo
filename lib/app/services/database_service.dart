// lib/app/services/database_service.dart

import 'dart:io';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/main.dart';

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
        .maybeSingle(); // CORREÇÃO: Usando maybeSingle() em vez de single()

    // Se a resposta for nula (nenhum perfil encontrado), retorna null.
    if (response == null || response.isEmpty) {
      return null;
    }
    return UserProfile.fromMap(response);
  }

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
}
