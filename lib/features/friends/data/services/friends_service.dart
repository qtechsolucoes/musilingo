// lib/features/friends/data/services/friends_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_model.dart';

class FriendsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para buscar a lista de amigos e pedidos
  Future<List<Friend>> getFriendsList() async {
    try {
      final response = await _supabase.functions.invoke('get_friends_list');
      final List<dynamic> data = response.data;
      return data.map((item) => Friend.fromJson(item)).toList();
    } catch (e) {
      // Idealmente, tratar o erro de forma mais robusta (logging, etc.)
      if (kDebugMode) {
        print('Erro ao buscar lista de amigos: $e');
      }
      return [];
    }
  }

  // Método para enviar um pedido de amizade
  Future<void> sendFriendRequest(String targetUserId) async {
    await _supabase.functions.invoke('handle_friend_request', body: {
      'target_user_id': targetUserId,
      'action': 'add',
    });
  }

  // Método para aceitar um pedido de amizade
  Future<void> acceptFriendRequest(String targetUserId) async {
    await _supabase.functions.invoke('handle_friend_request', body: {
      'target_user_id': targetUserId,
      'action': 'accept',
    });
  }

  // Método para remover ou recusar uma amizade
  Future<void> removeOrDeclineFriend(String targetUserId) async {
    await _supabase.functions.invoke('handle_friend_request', body: {
      'target_user_id': targetUserId,
      'action': 'remove',
    });
  }

  // Método para procurar por novos amigos
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase.functions
          .invoke('search_users', body: {'query': query});
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao procurar usuários: $e');
      }
      return [];
    }
  }
}
