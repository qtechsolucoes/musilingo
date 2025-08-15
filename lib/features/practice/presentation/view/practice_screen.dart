// lib/features/practice/presentation/view/practice_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/features/practice/presentation/view/harmonic_perception_list_screen.dart';
import 'package:musilingo/features/practice/presentation/view/harmonic_progression_list_screen.dart'; // <-- NOVO IMPORT
import 'package:musilingo/features/practice/presentation/view/melodic_perception_list_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Prática'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPracticeCard(
            context: context,
            icon: Icons.hearing,
            title: 'Percepção Melódica',
            subtitle: 'Ouça e transcreva pequenas melodias.',
            isEnabled: true,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const MelodicPerceptionListScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildPracticeCard(
            context: context,
            icon: Icons.grid_on,
            title: 'Percepção Harmônica',
            subtitle: 'Identifique os acordes que você ouvir.',
            isEnabled: true,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const HarmonicPerceptionListScreen()));
            },
          ),
          const SizedBox(height: 16),
          // --- NOVO CARTÃO ADICIONADO ---
          _buildPracticeCard(
            context: context,
            icon: Icons.format_list_numbered,
            title: 'Progressões Harmônicas',
            subtitle: 'Identifique sequências de acordes.',
            isEnabled: true,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const HarmonicProgressionListScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildPracticeCard(
            context: context,
            icon: Icons.mic,
            title: 'Solfeggio (Em breve)',
            subtitle: 'Cante as notas na altura e ritmo corretos.',
            isEnabled: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Card(
      color: isEnabled
          ? AppColors.card
          : Colors.grey.shade800.withAlpha((255 * 0.5).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: isEnabled ? AppColors.accent : Colors.grey.shade600,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isEnabled
                            ? AppColors.textSecondary
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isEnabled)
                const Text(
                  'Em breve',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
