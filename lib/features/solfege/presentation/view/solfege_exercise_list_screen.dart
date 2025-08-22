// lib/features/solfege/presentation/view/solfege_exercise_list_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/solfege/data/models/solfege_exercise_model.dart';
import 'package:musilingo/features/solfege/data/services/solfege_service.dart';
import 'package:musilingo/features/solfege/presentation/view/solfege_exercise_screen.dart';

class SolfegeExerciseListScreen extends StatefulWidget {
  final String difficultyLevel;
  final String difficultyTitle;

  const SolfegeExerciseListScreen({
    super.key,
    required this.difficultyLevel,
    required this.difficultyTitle,
  });

  @override
  State<SolfegeExerciseListScreen> createState() =>
      _SolfegeExerciseListScreenState();
}

class _SolfegeExerciseListScreenState extends State<SolfegeExerciseListScreen> {
  late Future<List<SolfegeExercise>> _exercisesFuture;
  final SolfegeService _solfegeService = SolfegeService();

  @override
  void initState() {
    super.initState();
    _exercisesFuture =
        _solfegeService.getExercisesByDifficulty(widget.difficultyLevel);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.difficultyTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<List<SolfegeExercise>>(
          future: _exercisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child:
                      Text('Erro ao carregar exercícios: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text('Nenhum exercício encontrado para este nível.'));
            }

            final exercises = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Card(
                  color: AppColors.card.withAlpha((255 * 0.8).round()),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    title: Text(exercise.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: AppColors.accent),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SolfegeExerciseScreen(
                            exercise: exercise,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
