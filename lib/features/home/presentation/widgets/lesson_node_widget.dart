// lib/features/home/presentation/widgets/lesson_node_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';

class LessonNodeWidget extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;

  const LessonNodeWidget({
    super.key,
    required this.lesson,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor;
    Color iconColor;
    IconData displayIcon;
    List<BoxShadow>? boxShadow;

    switch (lesson.status) {
      case LessonStatus.completed:
        nodeColor = const Color(0xFF6A4C93); // Roxo
        iconColor = Colors.white;
        displayIcon = Icons.check;
        break;
      case LessonStatus.unlocked:
        nodeColor = AppColors.accent; // Dourado
        iconColor = AppColors.background;
        displayIcon = lesson.icon;
        boxShadow = [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
        break;
      case LessonStatus.locked:
      default:
        nodeColor = Colors.grey.shade800;
        iconColor = Colors.grey.shade600;
        displayIcon = Icons.lock;
        break;
    }

    return GestureDetector(
      onTap: lesson.status != LessonStatus.locked ? onTap : null,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: nodeColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: boxShadow,
        ),
        child: Center(
          child: Icon(displayIcon, color: iconColor, size: 40),
        ),
      ),
    );
  }
}
