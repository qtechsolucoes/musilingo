// lib/shared/widgets/custom_text_field.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller; // ADICIONADO
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType; // ADICIONADO

  const CustomTextField({
    super.key,
    required this.controller, // ADICIONADO
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType, // ADICIONADO
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // ADICIONADO
      obscureText: obscureText,
      keyboardType: keyboardType, // ADICIONADO
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(prefixIcon, color: AppColors.accent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
