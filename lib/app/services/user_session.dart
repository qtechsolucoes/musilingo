// lib/app/services/user_session.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- IMPORT CORRIGIDO

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

  void answerCorrectly() {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      points: _currentUser!.points + 10,
      correctAnswers: _currentUser!.correctAnswers + 1,
    );
    _databaseService.updateStats(
      userId: _currentUser!.id,
      points: _currentUser!.points,
      correctAnswers: _currentUser!.correctAnswers,
    );
    _databaseService.upsertWeeklyXp(_currentUser!.id, 10);
    notifyListeners();
  }

  void answerWrongly() {
    if (_currentUser == null || _currentUser!.lives <= 0) return;
    _currentUser = _currentUser!.copyWith(
      lives: _currentUser!.lives - 1,
      wrongAnswers: _currentUser!.wrongAnswers + 1,
    );
    _databaseService.updateStats(
      userId: _currentUser!.id,
      lives: _currentUser!.lives,
      wrongAnswers: _currentUser!.wrongAnswers,
    );
    notifyListeners();
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
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    notifyListeners();
  }
}
