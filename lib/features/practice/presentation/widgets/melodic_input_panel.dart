// lib/features/practice/presentation/widgets/melodic_input_panel.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

class MelodicInputPanel extends StatelessWidget {
  final List<String> notePalette;
  final Map<String, String> figurePalette;
  final String selectedNote;
  final String selectedFigure;
  final bool isVerified;
  final ValueChanged<String> onNoteSelected;
  final ValueChanged<String> onFigureSelected;
  final VoidCallback onAddNote;
  final VoidCallback onRemoveLastNote;
  final VoidCallback onVerify;

  const MelodicInputPanel({
    super.key,
    required this.notePalette,
    required this.figurePalette,
    required this.selectedNote,
    required this.selectedFigure,
    required this.isVerified,
    required this.onNoteSelected,
    required this.onFigureSelected,
    required this.onAddNote,
    required this.onRemoveLastNote,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: notePalette
                          .map((note) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ActionChip(
                                  label: Text(note),
                                  backgroundColor: selectedNote == note
                                      ? AppColors.accent
                                      : AppColors.primary,
                                  onPressed: () => onNoteSelected(note),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: figurePalette.entries
                          .map((entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ActionChip(
                                  label: Text(entry.value),
                                  backgroundColor: selectedFigure == entry.key
                                      ? AppColors.accent
                                      : AppColors.primary,
                                  onPressed: () => onFigureSelected(entry.key),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(
              width: 24, indent: 8, endIndent: 8, color: Colors.white24),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onAddNote,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Nota"),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: onRemoveLastNote,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text("Desfazer"),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12)),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerified ? null : onVerify,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.completed),
                    child: const Text('Verificar Resposta'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
