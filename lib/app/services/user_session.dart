// lib/app/services/user_session.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/main.dart';
import 'package:intl/intl.dart';

class UserSession extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw 'Utilizador não autenticado.';
      }
      _currentUser = await _databaseService.createProfileOnLogin(user);
    } catch (e) {
      _errorMessage = "Erro ao carregar perfil: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> answerCorrectly() async {
    if (_currentUser == null) return;

    const pointsGained = 10; // Definimos os pontos ganhos como uma constante

    _currentUser!.points += pointsGained;
    _currentUser!.correctAnswers += 1;
    notifyListeners();

    // Atualiza os pontos totais na tabela 'profiles'
    await _databaseService.updateStats(
      userId: _currentUser!.id,
      points: _currentUser!.points,
      correctAnswers: _currentUser!.correctAnswers,
    );

    // --- NOVA LÓGICA ADICIONADA ---
    // Adiciona os mesmos pontos ao XP semanal na tabela 'weekly_xp'
    await _databaseService.upsertWeeklyXp(_currentUser!.id, pointsGained);
  }

  Future<void> answerWrongly() async {
    if (_currentUser == null || _currentUser!.lives <= 0) return;

    _currentUser!.lives -= 1;
    _currentUser!.wrongAnswers += 1;
    notifyListeners();

    await _databaseService.updateStats(
      userId: _currentUser!.id,
      lives: _currentUser!.lives,
      wrongAnswers: _currentUser!.wrongAnswers,
    );
  }

  Future<void> updateUserAvatar(String newAvatarUrl) async {
    if (_currentUser == null) return;
    _currentUser!.avatarUrl = newAvatarUrl;
    notifyListeners();
  }

  Future<void> recordPractice() async {
    if (_currentUser == null) return;

    final today = DateTime.now();
    final lastPractice = _currentUser!.lastPracticeDate;

    bool updateRequired = false;

    bool isNewDay(DateTime date1, DateTime date2) {
      return date1.year != date2.year ||
          date1.month != date2.month ||
          date1.day != date2.day;
    }

    if (lastPractice == null) {
      _currentUser!.currentStreak = 1;
      updateRequired = true;
    } else {
      if (isNewDay(today, lastPractice)) {
        final difference = today.difference(lastPractice).inDays;
        if (difference == 1) {
          _currentUser!.currentStreak++;
          updateRequired = true;
        } else if (difference > 1) {
          _currentUser!.currentStreak = 1;
          updateRequired = true;
        }
      }
    }

    if (updateRequired) {
      _currentUser!.lastPracticeDate = today;
      notifyListeners();

      await _databaseService.updateStats(
        userId: _currentUser!.id,
        currentStreak: _currentUser!.currentStreak,
        lastPracticeDate: DateFormat('yyyy-MM-dd').format(today),
      );
    }
  }
}
