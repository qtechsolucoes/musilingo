// lib/app/presentation/view/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/home/presentation/view/home_screen.dart';
import 'package:musilingo/features/practice/presentation/view/practice_screen.dart';
import 'package:musilingo/features/profile/presentation/view/profile_screen.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        Provider.of<UserSession>(context, listen: false)
            .loadUserProfile(userId);
      }
    });
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    PracticeScreen(),
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

    // Se estiver carregando, mostra o ícone e o indicador
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

    // Se houver um erro, mostra a mensagem de erro
    if (userSession.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ocorreu um problema:\n${userSession.errorMessage}\n\nPor favor, reinicie o aplicativo e verifique sua conexão.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    // Se tudo estiver certo, mostra a tela principal
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Aprender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Prática',
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
