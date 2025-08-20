// lib/app/presentation/view/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart'; // Importar AppColors
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/duel/presentation/view/duel_lobby_screen.dart';
import 'package:musilingo/features/friends/presentation/view/friends_screen.dart';
import 'package:musilingo/features/home/presentation/view/home_screen.dart';
import 'package:musilingo/features/practice/presentation/view/practice_screen.dart';

// Importar a nossa nova tela "Mais" que terá o navegador aninhado
import 'more_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // A lista de páginas agora inclui a nossa nova MoreScreen
  final List<Widget> _pages = [
    const HomeScreen(),
    const PracticeScreen(),
    const FriendsScreen(),
    const DuelLobbyScreen(),
    const MoreScreen(), // A aba "Mais" agora existe
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,

          // CORREÇÃO: Cor amarela para o ícone selecionado
          selectedItemColor: AppColors.accent,

          unselectedItemColor:
              Colors.white, // Cor branca para os não selecionados
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Aprender',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: 'Praticar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Amigos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_kabaddi),
              label: 'Duelo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Mais',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
