// lib/features/solfege/data/services/solfege_service.dart

import 'package:musilingo/features/solfege/data/models/solfege_exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SolfegeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SolfegeExercise>> getExercisesByDifficulty(
      String difficultyLevel) async {
    try {
      final response = await _supabase
          .from('practice_solfege')
          .select()
          .eq('difficulty_level', difficultyLevel)
          .order('difficulty_value', ascending: true);

      // O 'response' é uma List<Map<String, dynamic>>.
      // O construtor .fromJson que criamos no passo anterior fará todo o trabalho pesado.
      final exercises =
          response.map((item) => SolfegeExercise.fromJson(item)).toList();

      return exercises;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar exercícios de solfejo: $e');
      rethrow;
    }
  }
}
