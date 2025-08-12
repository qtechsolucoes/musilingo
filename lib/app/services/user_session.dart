// lib/app/services/user_session.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/services/database_service.dart';

class UserSession extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _databaseService.getProfile(userId);
    } catch (e) {
      _errorMessage = "Erro ao carregar perfil: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> answerCorrectly() async {
    if (_currentUser == null) return;

    _currentUser!.points += 10;
    _currentUser!.correctAnswers += 1;
    notifyListeners();

    await _databaseService.updateStats(
      userId: _currentUser!.id,
      points: _currentUser!.points,
      correctAnswers: _currentUser!.correctAnswers,
    );
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
}
