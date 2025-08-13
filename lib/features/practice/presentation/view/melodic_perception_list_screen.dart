// lib/features/practice/presentation/view/melodic_perception_list_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/features/practice/presentation/view/melodic_perception_exercise_screen.dart';
import 'package:musilingo/features/practice/presentation/widgets/exercise_node_widget.dart'; // Importa o novo widget

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
          const double nodeSpacing = 120.0;
          final double totalHeight = exercises.length * nodeSpacing;

          return SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              height: totalHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pinta o caminho da trilha
                  _buildPracticePath(exercises.length, nodeSpacing),
                  // Posiciona os nós dos exercícios
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
      List<MelodicExercise> exercises, double spacing) {
    return List.generate(exercises.length, (index) {
      final exercise = exercises[index];
      return Positioned(
        top: index * spacing + 20, // Adiciona um padding inicial
        child: ExerciseNodeWidget(
          exercise: exercise,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  MelodicPerceptionExerciseScreen(exercise: exercise),
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

// Um CustomPainter simples para desenhar a linha vertical da trilha
class _PracticePathPainter extends CustomPainter {
  final int nodeCount;
  final double spacing;

  _PracticePathPainter({required this.nodeCount, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      // ignore: deprecated_member_use
      ..color = AppColors.primary.withOpacity(0.6)
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
