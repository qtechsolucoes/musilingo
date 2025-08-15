// lib/features/practice/presentation/widgets/exercise_node_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

class ExerciseNodeWidget extends StatelessWidget {
  final String title;
  final int difficulty;
  final IconData icon; // Parâmetro de ícone adicionado
  final VoidCallback onTap;

  const ExerciseNodeWidget({
    super.key,
    required this.title,
    required this.difficulty,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 12.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.accent), // Ícone dinâmico
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Dificuldade: $difficulty',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill,
                size: 28, color: AppColors.completed),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
