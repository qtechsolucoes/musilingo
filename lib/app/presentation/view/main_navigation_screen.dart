// lib/app/presentation/view/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/home/presentation/view/home_screen.dart';
import 'package:musilingo/features/leagues/presentation/view/leagues_screen.dart'; // <-- NOVO IMPORT
import 'package:musilingo/features/practice/presentation/view/practice_screen.dart';
import 'package:musilingo/features/profile/presentation/view/profile_screen.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // LISTA DE TELAS ATUALIZADA
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    PracticeScreen(),
    LeaguesScreen(), // <-- NOVA TELA ADICIONADA
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSession>();

    if (userSession.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, size: 80, color: AppColors.accent),
              SizedBox(height: 20),
              CircularProgressIndicator(color: AppColors.accent),
            ],
          ),
        ),
      );
    }

    if (userSession.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ocorreu um problema:\n${userSession.errorMessage}\n\nPor favor, reinicie a aplicação e verifique a sua ligação.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // BARRA DE NAVEGAÇÃO ATUALIZADA
      bottomNavigationBar: BottomNavigationBar(
        // Adicionado para garantir que todos os itens apareçam
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Aprender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Prática',
          ),
          // NOVO ITEM DA BARRA DE NAVEGAÇÃO
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events), // Ícone de troféu
            label: 'Ligas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.white54,
        onTap: _onItemTapped,
      ),
    );
  }
}
