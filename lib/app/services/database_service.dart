// lib/app/services/database_service.dart

import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/features/lesson/data/models/question_model.dart';
import 'package:musilingo/main.dart';

class DatabaseService {
  Future<List<Module>> getModulesAndLessons() async {
    final response = await supabase
        .from('modules')
        .select('*, lessons(*)')
        .order('id', ascending: true);

    final List<Module> modules =
        (response as List).map((data) => Module.fromMap(data)).toList();
    return modules;
  }

  Future<Set<int>> getCompletedLessonIds(String userId) async {
    final response = await supabase
        .from('completed_lessons')
        .select('lesson_id')
        .eq('user_id', userId);

    final Set<int> ids =
        (response as List).map((data) => data['lesson_id'] as int).toSet();
    return ids;
  }

  // --- MÉTODO ADICIONADO ---
  Future<List<Question>> getQuestionsForLesson(int lessonId) async {
    final response = await supabase
        .from('questions')
        .select('*')
        .eq('lesson_id', lessonId)
        .order('id', ascending: true);

    final List<Question> questions =
        (response as List).map((data) => Question.fromMap(data)).toList();
    return questions;
  }

  // --- MÉTODO ADICIONADO ---
  Future<void> markLessonAsCompleted(String userId, int lessonId) async {
    await supabase.from('completed_lessons').insert({
      'user_id': userId,
      'lesson_id': lessonId,
    });
  }
}
