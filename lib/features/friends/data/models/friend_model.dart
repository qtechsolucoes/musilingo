// lib/features/friends/data/models/friend_model.dart

class Friend {
  final String id;
  final String username;
  final String? avatarUrl;
  final String friendshipType; // 'friend', 'pending_sent', 'pending_received'

  Friend({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.friendshipType,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['friend_id'],
      username: json['username'] ?? 'Usuário desconhecido',
      avatarUrl: json['avatar_url'],
      friendshipType: json['friendship_type'],
    );
  }
}
