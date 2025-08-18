// lib/app/presentation/view/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/features/challenges/presentation/view/challenges_screen.dart'; // IMPORTADO
import 'package:musilingo/features/home/presentation/view/home_screen.dart';
import 'package:musilingo/features/leagues/presentation/view/leagues_screen.dart';
import 'package:musilingo/features/practice/presentation/view/practice_screen.dart';
import 'package:musilingo/features/profile/presentation/view/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // **** NOVA TELA ADICIONADA À LISTA ****
  final List<Widget> _screens = [
    const HomeScreen(),
    const PracticeScreen(),
    const ChallengesScreen(), // TELA DE DESAFIOS
    const LeaguesScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 28, 28, 60),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Aprender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Prática',
          ),
          // **** NOVO ITEM NA BARRA DE NAVEGAÇÃO ****
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Desafios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ligas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
