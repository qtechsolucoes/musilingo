// lib/features/practice/presentation/widgets/melodic_input_panel.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';

enum AccidentalType { none, sharp, flat }

class MelodicInputPanel extends StatelessWidget {
  final Map<String, String> figurePalette;
  final Map<String, String> restPalette;
  final String selectedFigure;
  final ValueChanged<String> onFigureSelected;

  final VoidCallback onAddNote;
  final VoidCallback onAddRest;
  final VoidCallback onVerify;
  final bool isVerified;

  final int displayOctave;
  final VoidCallback onOctaveUp;
  final VoidCallback onOctaveDown;

  final AccidentalType currentAccidental;
  final ValueChanged<AccidentalType> onAccidentalSelected;

  final List<String> notePalette;
  final ValueChanged<String> onNoteSelected;
  final String selectedNote;

  const MelodicInputPanel({
    super.key,
    required this.figurePalette,
    required this.restPalette,
    required this.selectedFigure,
    required this.onFigureSelected,
    required this.onAddNote,
    required this.onAddRest,
    required this.onVerify,
    required this.isVerified,
    required this.displayOctave,
    required this.onOctaveUp,
    required this.onOctaveDown,
    required this.currentAccidental,
    required this.onAccidentalSelected,
    required this.notePalette,
    required this.onNoteSelected,
    required this.selectedNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fileira 1: Notas e Ações Principais
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Teclado de Notas
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: notePalette
                        .map((note) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: ActionChip(
                                label:
                                    Text(note.replaceAll(RegExp(r'[0-9]'), '')),
                                backgroundColor: selectedNote ==
                                        note.replaceAll(RegExp(r'[0-9]'), '')
                                    ? AppColors.accent
                                    : AppColors.primary,
                                onPressed: () => onNoteSelected(note),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Ações
              ElevatedButton(
                  onPressed: onAddNote, child: const Text("Adicionar Nota")),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: onAddRest, child: const Text("Adicionar Pausa")),
            ],
          ),
          const Divider(height: 12, color: Colors.white24),
          // Fileira 2: Figuras, Oitava, Acidentes e Verificação
          Row(
            children: [
              // Figuras e Pausas
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...figurePalette.entries.map(
                          (entry) => _buildFigureChip(entry.key, entry.value)),
                      const VerticalDivider(width: 16),
                      ...restPalette.entries.map(
                          (entry) => _buildFigureChip(entry.key, entry.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Controles
              _buildCompactControls(),
              const SizedBox(width: 16),
              // Botão Verificar
              ElevatedButton(
                onPressed: isVerified ? null : onVerify,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.completed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
                child: const Text('Verificar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFigureChip(String key, String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(symbol,
            style: const TextStyle(fontSize: 24, fontFamily: 'Roboto')),
        backgroundColor:
            selectedFigure == key ? AppColors.accent : AppColors.primary,
        onPressed: () => onFigureSelected(key),
      ),
    );
  }

  Widget _buildCompactControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Controle de Oitava
          Column(
            children: [
              const Text('Oitava',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 20),
                      onPressed: onOctaveDown,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                  Text(displayOctave.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 20),
                      onPressed: onOctaveUp,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Acidentes
          Column(
            children: [
              const Text('Acidente',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Row(
                children: [
                  IconButton(
                    icon: const Text('♭', style: TextStyle(fontSize: 24)),
                    color: currentAccidental == AccidentalType.flat
                        ? AppColors.accent
                        : Colors.white,
                    onPressed: () => onAccidentalSelected(AccidentalType.flat),
                  ),
                  IconButton(
                    icon: const Text('♯', style: TextStyle(fontSize: 24)),
                    color: currentAccidental == AccidentalType.sharp
                        ? AppColors.accent
                        : Colors.white,
                    onPressed: () => onAccidentalSelected(AccidentalType.sharp),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
