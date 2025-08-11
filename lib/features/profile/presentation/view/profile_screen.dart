// lib/features/profile/presentation/view/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Instancia nosso novo serviço
  final DatabaseService _databaseService = DatabaseService();

  // Tenta pegar o nome do usuário dos metadados do Supabase
  final String userName = supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Músico Dedicado';

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.person_pin, size: 120, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 32),
            const Text(
              'ESTATÍSTICAS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // Usamos um FutureBuilder para buscar e exibir o número de lições completas
            FutureBuilder<Set<int>>(
              // Chamamos nosso serviço, não mais o supabase diretamente
              future: _databaseService.getCompletedLessonIds(userId ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(color: AppColors.accent);
                }

                final completedCount = snapshot.data?.length ?? 0;

                return _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Lições Concluídas',
                  value: completedCount.toString(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar os cards de estatística
  Widget _buildStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 32),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 18)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}