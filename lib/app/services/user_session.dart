// lib/app/services/user_session.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/main.dart'; // Import para acesso ao 'supabase'
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSession extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> initializeSession() async {
    _isLoading = true;
    notifyListeners();
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      _currentUser = await _databaseService.getProfile(supabaseUser.id);
      if (_currentUser != null) {
        await _checkAndUpdateStreak();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile(User user) async {
    _currentUser = await _databaseService.createProfileOnLogin(user);
    notifyListeners();
  }

  Future<void> _checkAndUpdateStreak() async {
    if (_currentUser == null) return;

    final lastPracticeStr = _currentUser!.lastPracticeDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastPracticeStr != null && lastPracticeStr.isNotEmpty) {
      final lastPracticeDate = DateTime.parse(lastPracticeStr);
      final lastPracticeDay = DateTime(
          lastPracticeDate.year, lastPracticeDate.month, lastPracticeDate.day);

      final difference = today.difference(lastPracticeDay).inDays;

      if (difference > 1) {
        _currentUser = _currentUser!.copyWith(currentStreak: 0);
        await _databaseService.updateStats(
          userId: _currentUser!.id,
          currentStreak: 0,
        );
      }
    }
    notifyListeners();
  }

  Future<void> recordPractice() async {
    if (_currentUser == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPracticeStr = _currentUser!.lastPracticeDate;
    bool streakUpdated = false;

    if (lastPracticeStr != null && lastPracticeStr.isNotEmpty) {
      final lastPracticeDate = DateTime.parse(lastPracticeStr);
      final lastPracticeDay = DateTime(
          lastPracticeDate.year, lastPracticeDate.month, lastPracticeDate.day);

      if (lastPracticeDay.isBefore(today)) {
        final difference = today.difference(lastPracticeDay).inDays;
        if (difference == 1) {
          _currentUser = _currentUser!
              .copyWith(currentStreak: _currentUser!.currentStreak + 1);
        } else {
          _currentUser = _currentUser!.copyWith(currentStreak: 1);
        }
        streakUpdated = true;
      }
    } else {
      _currentUser = _currentUser!.copyWith(currentStreak: 1);
      streakUpdated = true;
    }

    _currentUser =
        _currentUser!.copyWith(lastPracticeDate: now.toIso8601String());

    await _databaseService.updateStats(
      userId: _currentUser!.id,
      lastPracticeDate: _currentUser!.lastPracticeDate,
      currentStreak: streakUpdated ? _currentUser!.currentStreak : null,
    );

    notifyListeners();
  }

  // --- MÉTODO ATUALIZADO ---
  // Usa a função RPC 'handle_correct_answer' para segurança e performance.
  Future<void> answerCorrectly() async {
    if (_currentUser == null) return;

    try {
      // Chama a função RPC no Supabase com a quantidade de pontos
      await supabase
          .rpc('handle_correct_answer', params: {'p_points_to_add': 10});

      // Atualiza o estado local para refletir a mudança imediatamente na UI
      _currentUser = _currentUser!.copyWith(
        points: _currentUser!.points + 10,
        correctAnswers: _currentUser!.correctAnswers + 1,
      );

      // Notifica os widgets que estão ouvindo para reconstruir com os novos valores.
      notifyListeners();
    } catch (error) {
      debugPrint("Erro ao chamar handle_correct_answer: $error");
      // Opcional: Adicionar lógica para reverter o estado local se a chamada falhar
    }
  }

  // --- MÉTODO ATUALIZADO ---
  // Usa a função RPC 'handle_wrong_answer' para segurança e consistência.
  Future<void> answerWrongly() async {
    if (_currentUser == null || _currentUser!.lives <= 0) return;

    try {
      // Chama a função RPC no Supabase
      await supabase.rpc('handle_wrong_answer');

      // Atualiza o estado local para refletir a mudança imediatamente na UI
      _currentUser = _currentUser!.copyWith(
        lives: _currentUser!.lives - 1,
        wrongAnswers: _currentUser!.wrongAnswers + 1,
      );

      notifyListeners();
    } catch (error) {
      debugPrint("Erro ao chamar handle_wrong_answer: $error");
    }
  }

  Future<void> updateAvatar(File image) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final newAvatarUrl =
          await _databaseService.uploadAvatar(_currentUser!.id, image);
      _currentUser = _currentUser!.copyWith(avatarUrl: newAvatarUrl);
    } catch (e) {
      // Tratar erro, se necessário
      debugPrint("Erro ao atualizar avatar: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    notifyListeners();
  }
}
