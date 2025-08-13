// lib/app/services/database_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
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

  // MÉTODO RESTAURADO
  Future<Set<int>> getCompletedLessonIds(String userId) async {
    final response = await supabase
        .from('completed_lessons')
        .select('lesson_id')
        .eq('user_id', userId);
    return (response as List).map((data) => data['lesson_id'] as int).toSet();
  }

  // MÉTODO RESTAURADO
  Future<List<LessonStep>> getStepsForLesson(int lessonId) async {
    final response = await supabase
        .from('lesson_steps')
        .select('*')
        .eq('lesson_id', lessonId)
        .order('step_index', ascending: true);
    return (response as List).map((data) => LessonStep.fromMap(data)).toList();
  }

  // MÉTODO RESTAURADO
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
      };
      await supabase.from('profiles').insert(newProfileData);

      return UserProfile.fromMap(newProfileData);
    }
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

  // MÉTODO RESTAURADO
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

  // MÉTODO RESTAURADO
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
