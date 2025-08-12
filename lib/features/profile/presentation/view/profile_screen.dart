// lib/features/profile/presentation/view/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _pickAndUploadAvatar() async {
    final userSession = context.read<UserSession>();
    final user = userSession.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      try {
        final newAvatarUrl = await _databaseService.uploadAvatar(user.id, file);
        userSession.updateUserAvatar(newAvatarUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Foto de perfil atualizada!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao enviar imagem: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserSession>().currentUser;

    if (user == null) {
      return const Center(child: Text("Carregando perfil..."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar do Usuário
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.card,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person,
                          size: 60, color: AppColors.accent)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon:
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: _pickAndUploadAvatar,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'ESTATÍSTICAS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Cards de Estatísticas
            _buildStatCard(
                icon: Icons.music_note,
                label: 'Pontos Totais',
                value: user.points.toString()),
            const SizedBox(height: 12),
            _buildStatCard(
                icon: Icons.check_circle_outline,
                label: 'Respostas Corretas',
                value: user.correctAnswers.toString()),
            const SizedBox(height: 12),
            _buildStatCard(
                icon: Icons.highlight_off,
                label: 'Respostas Erradas',
                value: user.wrongAnswers.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 18)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
