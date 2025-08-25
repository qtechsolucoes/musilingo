import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solfege_exercise.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _exercisesKey = 'cached_exercises';
  static const String _lastSyncKey = 'last_sync';
  static const Duration _cacheValidity = Duration(hours: 24);

  final Map<String, SolfegeExercise> _memoryCache = {};

  Future<List<SolfegeExercise>> getExercises(
      {bool forceRefresh = false}) async {
    // Verificar cache em memória primeiro
    if (_memoryCache.isNotEmpty && !forceRefresh) {
      return _memoryCache.values.toList();
    }

    // Verificar cache persistente
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);

    if (!forceRefresh && lastSync != null) {
      final lastSyncTime = DateTime.parse(lastSync);
      if (DateTime.now().difference(lastSyncTime) < _cacheValidity) {
        final cached = prefs.getString(_exercisesKey);
        if (cached != null) {
          return _loadFromCache(cached);
        }
      }
    }

    // Buscar do Supabase
    return await _fetchFromSupabase();
  }

  List<SolfegeExercise> _loadFromCache(String cached) {
    final List<dynamic> json = jsonDecode(cached);
    final exercises = json.map((e) => SolfegeExercise.fromJson(e)).toList();

    // Atualizar cache em memória
    _memoryCache.clear();
    for (final exercise in exercises) {
      _memoryCache[exercise.id] = exercise;
    }

    return exercises;
  }

  Future<List<SolfegeExercise>> _fetchFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('practice_solfege')
          .select()
          .order('difficulty_value', ascending: true);

      final exercises = (response as List)
          .map((json) => SolfegeExercise.fromJson(json))
          .toList();

      // Salvar em cache
      await _saveToCache(exercises);

      return exercises;
    } catch (e) {
      print('Erro ao buscar exercícios: $e');

      // Tentar retornar do cache mesmo expirado
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_exercisesKey);
      if (cached != null) {
        return _loadFromCache(cached);
      }

      throw e;
    }
  }

  Future<void> _saveToCache(List<SolfegeExercise> exercises) async {
    // Atualizar cache em memória
    _memoryCache.clear();
    for (final exercise in exercises) {
      _memoryCache[exercise.id] = exercise;
    }

    // Salvar cache persistente
    final prefs = await SharedPreferences.getInstance();
    final json = exercises
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'difficulty_level': e.difficultyLevel,
              'difficulty_value': e.difficultyValue,
              'key_signature': e.keySignature,
              'time_signature': e.timeSignature,
              'tempo': e.tempo,
              'note_sequence':
                  jsonEncode(e.noteSequence.map((n) => n.toJson()).toList()),
              'created_at': e.createdAt.toIso8601String(),
            })
        .toList();

    await prefs.setString(_exercisesKey, jsonEncode(json));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  void clearCache() async {
    _memoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exercisesKey);
    await prefs.remove(_lastSyncKey);
  }

  // Pré-carregar assets de áudio
  Future<void> preloadAudioAssets() async {
    // Pré-carregar soundfont e outros recursos
    // Implementar conforme necessário
  }
}
