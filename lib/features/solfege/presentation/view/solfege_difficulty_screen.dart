// lib/features/solfege/presentation/view/solfege_difficulty_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart'; // IMPORTAMOS O WIDGET PADRÃO
import 'package:musilingo/features/solfege/presentation/view/solfege_exercise_list_screen.dart';

class SolfegeDifficultyScreen extends StatelessWidget {
  const SolfegeDifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Solfejo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // UTILIZAMOS O ExerciseNodeWidget AQUI
            ExerciseNodeWidget(
              title: 'Básico',
              description: 'Intervalos e escalas fundamentais.',
              icon: Icons.looks_one, // Ícone sugestivo
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SolfegeExerciseListScreen(
                      difficultyLevel: 'basico',
                      difficultyTitle: 'Básico',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ExerciseNodeWidget(
              title: 'Intermediário',
              description: 'Melodias com saltos e ritmos variados.',
              icon: Icons.looks_two, // Ícone sugestivo
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SolfegeExerciseListScreen(
                      difficultyLevel: 'intermediario',
                      difficultyTitle: 'Intermediário',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ExerciseNodeWidget(
              title: 'Avançado',
              description: 'Cromatismo, modulações e ritmos complexos.',
              icon: Icons.looks_3, // Ícone sugestivo
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SolfegeExerciseListScreen(
                      difficultyLevel: 'avancado',
                      difficultyTitle: 'Avançado',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ExerciseNodeWidget(
              title: 'Mestre',
              description: 'Trechos desafiadores de alta velocidade.',
              icon: Icons.star, // Ícone sugestivo
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SolfegeExerciseListScreen(
                      difficultyLevel: 'mestre',
                      difficultyTitle: 'Mestre',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
