// lib/features/home/presentation/widgets/lesson_node_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';

enum LessonStatus { locked, unlocked, completed }

class LessonNodeWidget extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;
  final LessonStatus status;

  const LessonNodeWidget({
    super.key,
    required this.lesson,
    this.onTap,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor;
    Color iconColor;
    IconData displayIcon;
    List<BoxShadow>? boxShadow;

    switch (status) {
      case LessonStatus.completed:
        nodeColor = const Color(0xFF6A4C93); // Roxo
        iconColor = Colors.white;
        displayIcon = Icons.check;
        break;
      case LessonStatus.unlocked:
        nodeColor = AppColors.accent; // Dourado
        iconColor = AppColors.background;
        displayIcon = Icons.music_note;
        boxShadow = [
          BoxShadow(
            color: AppColors.accent.withAlpha(128),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
        break;
      case LessonStatus.locked:
      default:
        nodeColor = Colors.grey.shade800;
        iconColor = Colors.grey.shade600;
        displayIcon = Icons.lock_outline;
        break;
    }

    return GestureDetector(
      onTap: status != LessonStatus.locked ? onTap : null,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: nodeColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: boxShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- CORREÇÃO DO ÍCONE ---
            Icon(displayIcon, color: iconColor, size: 36), // Tamanho do ícone reduzido
            const SizedBox(height: 6), // Espaçamento ajustado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: iconColor.withAlpha(200),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }
}