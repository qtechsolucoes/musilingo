// lib/app/services/database_service.dart

import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/main.dart'; // Para ter acesso ao 'supabase'

class DatabaseService {
  // Busca todos os módulos e suas respectivas lições.
  Future<List<Module>> getModulesAndLessons() async {
    final response = await supabase
        .from('modules')
        .select('*, lessons(*)')
        .order('order', ascending: true);

    final modules = List<Module>.from(
      response.map((map) => Module.fromMap(map)),
    );

    // Ordena as lições dentro de cada módulo
    for (final module in modules) {
      module.lessons.sort((a, b) => a.order.compareTo(b.order));
    }
    return modules;
  }

  // Busca os IDs de todas as lições que um usuário completou.
  Future<Set<int>> getCompletedLessonIds(String userId) async {
    final response = await supabase
        .from('user_lesson_progress')
        .select('lesson_id')
        .eq('user_id', userId);

    final completedLessonIds = Set<int>.from(
      response.map((item) => item['lesson_id']),
    );
    return completedLessonIds;
  }
}