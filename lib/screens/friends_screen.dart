import 'package:flutter/material.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/friend_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> _friends = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final friends = await FriendService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _openChat(dynamic friend) {
    final friendId = friend['_id'] ?? friend['id'];
    final friendName = friend['name'] ?? 'Friend';
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {'userId': friendId, 'name': friendName},
    );
  }

  Future<void> _removeFriend(String id) async {
    try {
      await FriendService.removeFriend(id);
      await _loadFriends();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.pushNamed(context, '/friend_requests'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_friend'),
        child: const Icon(Icons.person_search),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _friends.isEmpty
          ? const Center(child: Text('No friends yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final f = _friends[index];
                final name = f['name'] ?? 'Unknown';
                final email = f['email'] ?? '';
                final id = f['_id'] ?? f['id'];
                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text(email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () => _openChat(f),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeFriend(id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
