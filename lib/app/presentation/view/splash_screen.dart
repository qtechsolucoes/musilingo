// lib/app/presentation/view/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/view/main_navigation_screen.dart';
import 'package:musilingo/features/onboarding/presentation/view/onboarding_screen.dart';
import 'package:musilingo/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Chama a função de redirecionamento após um pequeno atraso
    _redirect();
  }

  Future<void> _redirect() async {
    // Aguarda um momento para a tela de splash ser visível
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session != null) {
      // Se houver uma sessão, vai para a tela principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      // Se não houver sessão, vai para o onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uma tela de carregamento simples com o logo
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 80, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
