// lib/features/leagues/presentation/widgets/league_list_item_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/weekly_xp_model.dart';

class LeagueListItemWidget extends StatelessWidget {
  final WeeklyXp leaderboardEntry;
  final int rank;
  final bool isCurrentUser;

  const LeagueListItemWidget({
    super.key,
    required this.leaderboardEntry,
    required this.rank,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final user = leaderboardEntry.userProfile;
    if (user == null) {
      return const SizedBox
          .shrink(); // Não mostra nada se o perfil não carregar
    }

    // Cores e ícones baseados na posição do ranking
    Color rankColor = AppColors.textSecondary;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Ouro
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Prata
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Posição no Ranking
          SizedBox(
            width: 40,
            child: Row(
              children: [
                if (rankIcon != null)
                  Icon(rankIcon, color: rankColor, size: 24)
                else
                  Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.background,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? const Icon(Icons.person, size: 24, color: AppColors.accent)
                : null,
          ),
          const SizedBox(width: 16),
          // Nome do Utilizador
          Expanded(
            child: Text(
              user.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          // Pontos (XP)
          Text(
            '${leaderboardEntry.xp} XP',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
