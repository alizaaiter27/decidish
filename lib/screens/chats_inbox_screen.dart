import 'package:flutter/material.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/api_service.dart';
import 'package:decidish/services/friend_service.dart';

/// Main-tab inbox: list friends and open a 1:1 [ChatScreen] per friend.
class ChatsInboxScreen extends StatefulWidget {
  const ChatsInboxScreen({super.key});

  @override
  State<ChatsInboxScreen> createState() => _ChatsInboxScreenState();
}

class _ChatsInboxScreenState extends State<ChatsInboxScreen> {
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
          _error = e is ApiException
              ? e.message
              : e.toString().replaceAll('ApiException: ', '');
          _loading = false;
        });
      }
    }
  }

  void _openChat(String friendId, String friendName) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/chat',
      arguments: {'userId': friendId, 'name': friendName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined, color: AppColors.textDark),
            tooltip: 'Friends',
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/friends');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadFriends,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFriends,
              child: _friends.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                        ),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 56,
                          color: AppColors.textLight.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No conversations yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Add friends from the Friends screen, then open a chat from here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed('/friends');
                            },
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Find friends'),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: _friends.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final f = _friends[index];
                        final name = f is Map
                            ? (f['name']?.toString().trim().isNotEmpty == true
                                  ? f['name'].toString()
                                  : 'Member')
                            : 'Member';
                        final email = f is Map
                            ? (f['email']?.toString() ?? '')
                            : '';
                        final id = FriendService.friendIdFromMap(f);
                        final initial = name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?';
                        return Material(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.secondary,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            subtitle: email.isNotEmpty
                                ? Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textLight,
                                    ),
                                  )
                                : null,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textLight,
                            ),
                            onTap: id.isEmpty
                                ? null
                                : () => _openChat(id, name),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
