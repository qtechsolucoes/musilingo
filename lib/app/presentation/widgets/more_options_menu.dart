// lib/app/presentation/widgets/more_options_menu.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/leagues/presentation/view/leagues_screen.dart';
import 'package:musilingo/features/profile/presentation/view/profile_screen.dart';

class MoreOptionsMenu extends StatelessWidget {
  const MoreOptionsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Em vez de um Dialog, usamos um Material para ter controlo total sobre a aparência
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200, // Largura do menu
        height: 120, // Altura do menu
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(128), // 50% de opacidade
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: GradientBackground(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMenuOption(
                  context,
                  icon: Icons.shield,
                  label: 'Ligas',
                  onTap: () {
                    // Primeiro fecha o popover, depois navega
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const LeaguesScreen(),
                    ));
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.person,
                  label: 'Perfil',
                  onTap: () {
                    // Primeiro fecha o popover, depois navega
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
