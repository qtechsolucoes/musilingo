// lib/app/data/models/lesson_model.dart
import 'package:flutter/material.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';

enum LessonStatus { locked, unlocked, completed }

class Lesson {
  final String title;
  final IconData icon;
  final LessonStatus status;
  final List<LessonStep> steps; // <-- ATUALIZADO AQUI

  Lesson({
    required this.title,
    required this.icon,
    required this.status,
    required this.steps, // <-- ATUALIZADO AQUI
  });
}
