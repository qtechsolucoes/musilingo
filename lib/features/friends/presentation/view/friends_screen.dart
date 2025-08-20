// lib/features/friends/presentation/view/friends_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/friends/data/models/friend_model.dart';
import 'package:musilingo/features/friends/data/services/friends_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  // ... (toda a lógica permanece a mesma)
  final FriendsService _friendsService = FriendsService();
  late final TabController _tabController;
  List<Friend> _friends = [];
  List<Friend> _pendingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFriendsData();
  }

  Future<void> _fetchFriendsData() async {
    setState(() => _isLoading = true);
    final allFriendships = await _friendsService.getFriendsList();

    if (mounted) {
      setState(() {
        _friends =
            allFriendships.where((f) => f.friendshipType == 'friend').toList();
        _pendingRequests = allFriendships
            .where((f) => f.friendshipType == 'pending_received')
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    final results = await _friendsService.searchUsers(query);
    if (mounted) setState(() => _searchResults = results);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AQUI ESTÁ A CORREÇÃO PRINCIPAL
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Amigos'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Amigos', icon: Icon(Icons.people)),
              Tab(text: 'Pedidos', icon: Icon(Icons.person_add)),
              Tab(text: 'Adicionar', icon: Icon(Icons.search)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildFriendsListTab(),
                  _buildPendingRequestsTab(),
                  _buildAddFriendTab(),
                ],
              ),
      ),
    );
  }

  // ... (os outros métodos de build continuam iguais)
  Widget _buildFriendsListTab() {
    if (_friends.isEmpty) {
      return const Center(child: Text('Você ainda não tem amigos.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: friend.avatarUrl != null
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null
                  ? Text(friend.username[0].toUpperCase())
                  : null,
            ),
            title: Text(friend.username),
            trailing: IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.redAccent),
              tooltip: 'Remover amigo',
              onPressed: () async {
                await _friendsService.removeOrDeclineFriend(friend.id);
                _fetchFriendsData();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return const Center(child: Text('Nenhum pedido pendente.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: request.avatarUrl != null
                  ? NetworkImage(request.avatarUrl!)
                  : null,
              child: request.avatarUrl == null
                  ? Text(request.username[0].toUpperCase())
                  : null,
            ),
            title: Text(request.username),
            subtitle: const Text('Enviou um pedido de amizade'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'Aceitar',
                  onPressed: () async {
                    await _friendsService.acceptFriendRequest(request.id);
                    _fetchFriendsData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  tooltip: 'Recusar',
                  onPressed: () async {
                    await _friendsService.removeOrDeclineFriend(request.id);
                    _fetchFriendsData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddFriendTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Procurar por username',
              suffixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white24,
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
                    child: Text('Digite para procurar por usuários.'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final username = user['username'] as String? ?? 'Usuário';
                      final avatarUrl = user['avatar_url'] as String?;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Text(username[0].toUpperCase())
                                : null,
                          ),
                          title: Text(username),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add_alt_1,
                                color: Colors.blue),
                            tooltip: 'Adicionar amigo',
                            onPressed: () async {
                              await _friendsService
                                  .sendFriendRequest(user['id']);

                              if (!mounted) return;

                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Pedido enviado para $username'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
