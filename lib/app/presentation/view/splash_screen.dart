// lib/app/presentation/view/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/view/main_navigation_screen.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/onboarding/presentation/view/onboarding_screen.dart';
import 'package:musilingo/features/auth/presentation/view/login_screen.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndRedirect();
  }

  Future<void> _initializeAndRedirect() async {
    // Espera um segundo para a splash screen ser visível e a UI inicializar
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session != null) {
      try {
        // ETAPA 1: Tenta carregar o perfil do usuário logado
        await context.read<UserSession>().loadUserProfile();

        if (mounted) {
          // ETAPA 2 (SUCESSO): Navega para a tela principal
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const MainNavigationScreen()),
          );
        }
      } catch (e) {
        // ETAPA 2 (FALHA): Se houver erro (rede, etc.), desloga e vai para o login
        await supabase.auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.primary,
              content:
                  Text('Sua sessão expirou. Por favor, faça login novamente.'),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } else {
      // Se não houver sessão, vai para a tela de Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 100, color: AppColors.accent),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Carregando...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
