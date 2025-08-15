// lib/features/leagues/presentation/view/leagues_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/data/models/weekly_xp_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/leagues/presentation/widgets/league_list_item_widget.dart';
import 'package:provider/provider.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  late Future<List<WeeklyXp>> _leaderboardFuture;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    final user = context.read<UserSession>().currentUser;
    // Inicia o carregamento do ranking da liga do utilizador atual
    _leaderboardFuture = _fetchLeaderboard(user);
  }

  Future<List<WeeklyXp>> _fetchLeaderboard(UserProfile? user) async {
    if (user == null) {
      // Se não houver utilizador, retorna uma lista vazia
      return [];
    }
    return _databaseService.getLeagueLeaderboard(user.league);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserSession>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Liga ${user?.league ?? ""}'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: FutureBuilder<List<WeeklyXp>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar o ranking: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
                    'Ainda não há ninguém no ranking desta liga. Comece a praticar!'));
          }

          final leaderboard = snapshot.data!;

          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return LeagueListItemWidget(
                leaderboardEntry: entry,
                rank: index + 1,
                isCurrentUser: entry.userId == user?.id,
              );
            },
          );
        },
      ),
    );
  }
}
