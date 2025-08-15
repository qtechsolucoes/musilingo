// lib/features/practice/presentation/view/harmonic_perception_list_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/harmonic_exercise_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/features/practice/presentation/view/harmonic_perception_exercise_screen.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart';

class HarmonicPerceptionListScreen extends StatefulWidget {
  const HarmonicPerceptionListScreen({super.key});

  @override
  State<HarmonicPerceptionListScreen> createState() =>
      _HarmonicPerceptionListScreenState();
}

class _HarmonicPerceptionListScreenState
    extends State<HarmonicPerceptionListScreen> {
  late Future<List<HarmonicExercise>> _exercisesFuture;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _databaseService.getHarmonicExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Percepção Harmônica'),
        backgroundColor: AppColors.background,
      ),
      body: FutureBuilder<List<HarmonicExercise>>(
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
              child: Text('Nenhum exercício de harmonia encontrado.'),
            );
          }

          final exercises = snapshot.data!;
          const double nodeSpacing = 120.0;
          final double totalHeight = exercises.length * nodeSpacing;

          return SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              height: totalHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPracticePath(exercises.length, nodeSpacing),
                  ..._buildExerciseNodes(exercises, nodeSpacing),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildExerciseNodes(
      List<HarmonicExercise> exercises, double spacing) {
    return List.generate(exercises.length, (index) {
      final exercise = exercises[index];
      return Positioned(
        top: index * spacing + 20,
        child: ExerciseNodeWidget(
          title: exercise.title,
          difficulty: exercise.difficulty,
          icon: Icons.grid_on, // Ícone específico para harmonia
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  HarmonicPerceptionExerciseScreen(exercise: exercise),
            ));
          },
        ),
      );
    });
  }

  Widget _buildPracticePath(int count, double spacing) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PracticePathPainter(nodeCount: count, spacing: spacing),
    );
  }
}

class _PracticePathPainter extends CustomPainter {
  final int nodeCount;
  final double spacing;

  _PracticePathPainter({required this.nodeCount, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withAlpha((255 * 0.6).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    if (nodeCount <= 1) return;

    final startY = (spacing / 2) + 20;
    final endY = (nodeCount - 1) * spacing + (spacing / 2);
    final centerX = size.width / 2;

    canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
