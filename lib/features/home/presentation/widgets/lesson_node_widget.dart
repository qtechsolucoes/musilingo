// lib/features/home/presentation/widgets/lesson_node_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';

enum LessonStatus { locked, unlocked, completed }

class LessonNodeWidget extends StatelessWidget {
  final Lesson lesson;
  final LessonStatus status;
  final VoidCallback onTap;

  const LessonNodeWidget({
    super.key,
    required this.lesson,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData iconData;
    Color iconColor = Colors.white;
    bool isEnabled = status != LessonStatus.locked;

    switch (status) {
      case LessonStatus.locked:
        backgroundColor = Colors.grey[800]!;
        iconData = Icons.lock;
        iconColor = Colors.white.withOpacity(0.7);
        break;
      case LessonStatus.unlocked:
        backgroundColor = AppColors.primary;
        iconData = Icons.music_note;
        break;
      case LessonStatus.completed:
        backgroundColor = AppColors.accent;
        iconData = Icons.check;
        break;
    }

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 100,
        height: 100,
        // *** DECORAÇÃO COM SOMBRA ADICIONADA AQUI ***
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10.0, // A intensidade do desfoque
              spreadRadius: 1.0, // O quanto a sombra se espalha
              offset: const Offset(
                  0, 5), // Deslocamento: 0 na horizontal, 5 para baixo
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 36, color: iconColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
