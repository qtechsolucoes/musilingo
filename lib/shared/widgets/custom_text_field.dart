// lib/shared/widgets/custom_text_field.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(prefixIcon, color: AppColors.accent),
        // Estilo da borda quando o campo não está focado.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        // Estilo da borda quando o usuário clica no campo.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
