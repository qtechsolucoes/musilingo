// lib/features/practice/presentation/view/melodic_perception_list_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart'; // <-- CORREÇÃO: Caminho do import ajustado
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/features/practice/presentation/view/melodic_perception_exercise_screen.dart';

class MelodicPerceptionListScreen extends StatefulWidget {
  const MelodicPerceptionListScreen({super.key});

  @override
  State<MelodicPerceptionListScreen> createState() =>
      _MelodicPerceptionListScreenState();
}

class _MelodicPerceptionListScreenState
    extends State<MelodicPerceptionListScreen> {
  late Future<List<MelodicExercise>> _exercisesFuture;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _databaseService.getMelodicExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Percepção Melódica'),
        backgroundColor: AppColors.background,
      ),
      body: FutureBuilder<List<MelodicExercise>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar exercícios: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhum exercício encontrado.'),
            );
          }

          final exercises = snapshot.data!;

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Card(
                color: AppColors.card,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading:
                      const Icon(Icons.music_note, color: AppColors.accent),
                  title: Text(exercise.title),
                  subtitle: Text('Dificuldade: ${exercise.difficulty}'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          MelodicPerceptionExerciseScreen(exercise: exercise),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
