// lib/features/duel/services/duel_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:musilingo/main.dart';
import 'package:musilingo/features/duel/data/models/duel_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DuelService {
  final _supabase = supabase;
  String? currentDuelId;
  RealtimeChannel? _duelChannel;

  final _duelController = StreamController<Duel?>.broadcast();
  Stream<Duel?> get duelStream => _duelController.stream;

  final _participantsController =
      StreamController<List<DuelParticipant>>.broadcast();
  Stream<List<DuelParticipant>> get participantsStream =>
      _participantsController.stream;

  final _questionsController = StreamController<List<DuelQuestion>>.broadcast();
  Stream<List<DuelQuestion>> get questionsStream => _questionsController.stream;

  // ... (Nenhuma alteração nas outras funções, elas já estão corretas)
  Future<String> findOrCreateDuel(String userId) async {
    try {
      final searchingDuels = await _supabase
          .from('duels')
          .select('id, duel_participants(user_id)')
          .eq('status', 'searching');

      final availableDuel = searchingDuels.firstWhere(
        (d) =>
            d['duel_participants'].isEmpty ||
            d['duel_participants'][0]['user_id'] != userId,
        orElse: () => <String, dynamic>{},
      );

      if (availableDuel.isNotEmpty) {
        currentDuelId = availableDuel['id'];
        await _joinDuel(currentDuelId!, userId);
        await _supabase
            .from('duels')
            .update({'status': 'ongoing'}).eq('id', currentDuelId!);
        await _generateDuelQuestions(currentDuelId!);
      } else {
        final newDuel = await _supabase
            .from('duels')
            .insert({'status': 'searching'})
            .select('id')
            .single();
        currentDuelId = newDuel['id'];
        await _joinDuel(currentDuelId!, userId);
      }

      listenToDuelUpdates(currentDuelId!);
      return currentDuelId!;
    } catch (e) {
      debugPrint('Erro em findOrCreateDuel: $e');
      throw Exception('Não foi possível encontrar ou criar um duelo.');
    }
  }

  Future<void> _joinDuel(String duelId, String userId) async {
    await _supabase
        .from('duel_participants')
        .insert({'duel_id': duelId, 'user_id': userId});
  }

  Future<void> _generateDuelQuestions(String duelId) async {
    final List<Map<String, dynamic>> questions = [
      {
        'duel_id': duelId,
        'question_text': 'Qual nota está na terceira linha da clave de Sol?',
        'options': ['Sol', 'Si', 'Ré', 'Fá'],
        'correct_answer': 'Si'
      },
      {
        'duel_id': duelId,
        'question_text': 'Quantos tempos dura uma semínima?',
        'options': ['1 tempo', '2 tempos', '4 tempos', 'Meio tempo'],
        'correct_answer': '1 tempo'
      },
      {
        'duel_id': duelId,
        'question_text': 'O que significa "piano" em dinâmica musical?',
        'options': [
          'Tocar forte',
          'Tocar rápido',
          'Tocar suave',
          'Tocar devagar'
        ],
        'correct_answer': 'Tocar suave'
      },
    ];
    await _supabase.from('duel_questions').insert(questions);
  }

  Future<void> submitAnswer(
      String questionId, String answer, String userId) async {
    await _supabase.rpc('submit_duel_answer', params: {
      'p_question_id': questionId,
      'p_user_id': userId,
      'p_answer': answer
    });
  }

  // ==================== INÍCIO DA CORREÇÃO ====================
  void listenToDuelUpdates(String duelId) {
    _duelChannel = _supabase.channel('duel_room_$duelId');

    // Sintaxe antiga removida. Nova sintaxe abaixo:
    _duelChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Substitui RealtimeListenTypes
          schema: 'public',
          table: 'duels',
          // Novo jeito de criar filtros
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: duelId,
          ),
          callback: (payload) => _fetchDuelAndParticipants(duelId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'duel_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duel_id',
            value: duelId,
          ),
          callback: (payload) => _fetchDuelAndParticipants(duelId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'duel_questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duel_id',
            value: duelId,
          ),
          callback: (payload) => _fetchQuestions(duelId),
        )
        .subscribe((status, [ref]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // O status também mudou
        await _fetchDuelAndParticipants(duelId);
        await _fetchQuestions(duelId);
      }
    });
  }
  // ===================== FIM DA CORREÇÃO ======================

  Future<void> _fetchDuelAndParticipants(String duelId) async {
    try {
      final duelData =
          await _supabase.from('duels').select().eq('id', duelId).single();
      if (!_duelController.isClosed) {
        _duelController.add(Duel.fromJson(duelData));
      }

      final participantsData = await _supabase
          .from('duel_participants')
          .select('*, profiles(username, avatar_url)')
          .eq('duel_id', duelId);
      final participants = participantsData
          .map<DuelParticipant>((p) => DuelParticipant.fromJson(p))
          .toList();
      if (!_participantsController.isClosed) {
        _participantsController.add(participants);
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados do duelo: $e');
    }
  }

  Future<void> _fetchQuestions(String duelId) async {
    try {
      final questionsData =
          await _supabase.from('duel_questions').select().eq('duel_id', duelId);
      final questions = questionsData
          .map<DuelQuestion>((q) => DuelQuestion.fromJson(q))
          .toList();
      if (!_questionsController.isClosed) {
        _questionsController.add(questions);
      }
    } catch (e) {
      debugPrint('Erro ao buscar perguntas do duelo: $e');
    }
  }

  Future<void> cancelSearch() async {
    if (currentDuelId != null) {
      await _supabase.from('duels').delete().eq('id', currentDuelId!);
    }
    dispose();
  }

  void dispose() {
    if (_duelChannel != null) {
      _supabase.removeChannel(_duelChannel!);
      _duelChannel = null;
    }
    _duelController.close();
    _participantsController.close();
    _questionsController.close();
  }
}
