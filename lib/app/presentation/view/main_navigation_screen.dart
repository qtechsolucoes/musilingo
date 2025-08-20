// lib/app/presentation/view/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/presentation/widgets/more_options_menu.dart';
import 'package:musilingo/features/duel/presentation/view/duel_lobby_screen.dart';
import 'package:musilingo/features/friends/presentation/view/friends_screen.dart';
import 'package:musilingo/features/home/presentation/view/home_screen.dart';
import 'package:musilingo/features/practice/presentation/view/practice_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  OverlayEntry? _moreMenuOverlayEntry;

  final List<Widget> _pages = [
    const HomeScreen(),
    const PracticeScreen(),
    const FriendsScreen(),
    const DuelLobbyScreen(),
  ];

  void _dismissMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
  }

  void _showMoreMenu() {
    if (_moreMenuOverlayEntry != null) return;

    final overlay = Overlay.of(context);

    _moreMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissMoreMenu,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            const Positioned(
              bottom: kBottomNavigationBarHeight + 10,
              right: 10,
              child: MoreOptionsMenu(),
            ),
          ],
        );
      },
    );

    overlay.insert(_moreMenuOverlayEntry!);
  }

  void _onItemTapped(int index) {
    if (index != 4 && _moreMenuOverlayEntry != null) {
      _dismissMoreMenu();
    }

    if (index == 4) {
      _showMoreMenu();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. A TELA INTEIRA AGORA É ENVOLVIDA PELO GRADIENTE
    return GradientBackground(
      child: Scaffold(
        // 2. O FUNDO DO SCAFFOLD É TRANSPARENTE
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          // 3. A BARRA DE NAVEGAÇÃO TAMBÉM É TRANSPARENTE
          backgroundColor: Colors.transparent,
          elevation: 0, // Remove a sombra/linha que separa a barra do conteúdo
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withAlpha(153), // ~60% opacidade
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
            // 4. ÍCONE DE DUELO ATUALIZADO
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
