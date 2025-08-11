// lib/features/onboarding/presentation/view/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/features/auth/presentation/view/login_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Modelo para representar os dados de cada página do onboarding.
class OnboardingPageData {
  final String imagePath;
  final String title;
  final String subtitle;

  OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  bool _isLastPage = false;

  // Dados para cada uma das nossas páginas de onboarding com os SVGs.
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      imagePath: 'assets/images/maestro.svg',
      title: 'Aprenda Música',
      subtitle: 'Domine as habilidades para ler partituras e tocar instrumentos.',
    ),
    OnboardingPageData(
      imagePath: 'assets/images/pentagrama.svg',
      title: 'Pratique de Forma Divertida',
      subtitle: 'Exercícios gamificados de ritmo, melodia e harmonia.',
    ),
    OnboardingPageData(
      imagePath: 'assets/images/trofeu.svg',
      title: 'Avance na sua Jornada',
      subtitle: 'Suba nas ligas, ganhe pontos e torne-se um mestre da música.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _isLastPage = index == _pages.length - 1;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Usamos o SvgPicture para renderizar nossas ilustrações.
                        SvgPicture.asset(
                          page.imagePath,
                          height: 180,
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Indicador de página (as bolinhas)
              SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: const WormEffect(
                  dotColor: Colors.white24,
                  activeDotColor: AppColors.accent,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
              const SizedBox(height: 32),

              // Botão principal com lógica de navegação
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isLastPage) {
                      // Se for a última página, navega para a tela de login.
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    } else {
                      // Se não, avança para a próxima página.
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isLastPage ? 'COMEÇAR' : 'PRÓXIMO',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botão secundário com lógica de navegação
              TextButton(
                onPressed: () {
                  // Navega diretamente para a tela de login.
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'EU JÁ TENHO UMA CONTA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
