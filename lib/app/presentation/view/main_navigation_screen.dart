// lib/app/presentation/view/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/sfx_service.dart';
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
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    PracticeScreen(),
    LeaguesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    // --- SOM DE CLIQUE ADICIONADO AQUI ---
    SfxService.instance.playClick();
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
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories, size: 28),
              label: 'Aprender',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/maestro.svg',
                height: 24,
                colorFilter: ColorFilter.mode(
                    _selectedIndex == 1
                        ? AppColors.accent
                        : Colors.grey.shade400,
                    BlendMode.srcIn),
              ),
              label: 'Prática',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/trofeu.svg',
                height: 24,
                colorFilter: ColorFilter.mode(
                    _selectedIndex == 2
                        ? AppColors.accent
                        : Colors.grey.shade400,
                    BlendMode.srcIn),
              ),
              label: 'Ligas',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
