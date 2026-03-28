import 'dart:async';

import 'package:flutter/material.dart';
import 'package:decidish/services/api_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/friend_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<dynamic> _friends = [];
  Set<String> _friendIds = {};

  List<dynamic> _searchResults = [];
  bool _searchLoading = false;
  String? _searchError;

  bool _loading = true;
  String? _error;

  int _pendingRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadPendingRequestCount();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequestCount() async {
    try {
      final reqs = await FriendService.getIncomingRequests();
      if (mounted) {
        setState(() => _pendingRequestCount = reqs.length);
      }
    } catch (_) {}
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final friends = await FriendService.getFriends();
      if (mounted) {
        final ids = <String>{};
        for (final f in friends) {
          final id = FriendService.friendIdFromMap(f);
          if (id.isNotEmpty) ids.add(id);
        }
        setState(() {
          _friends = friends;
          _friendIds = ids;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('ApiException: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadFriends();
    await _loadPendingRequestCount();
  }

  void _onSearchTextChanged(String _) {
    final q = _searchController.text.trim();
    _searchDebounce?.cancel();
    setState(() {});

    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _searchLoading = false;
        _searchError = null;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searchLoading = true;
      _searchError = null;
    });
    try {
      final res = await FriendService.searchUsers(query);
      if (!mounted) return;
      final filtered = res.where((u) {
        final id = FriendService.friendIdFromMap(u);
        return id.isNotEmpty && !_friendIds.contains(id);
      }).toList();
      setState(() {
        _searchResults = filtered;
        _searchLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searchLoading = false;
        _searchError = e is ApiException
            ? e.message
            : e.toString().replaceAll('ApiException: ', '');
      });
    }
  }

  Future<void> _sendRequest(dynamic user) async {
    final userId = FriendService.friendIdFromMap(user);
    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read user id')),
      );
      return;
    }
    try {
      await FriendService.sendRequest(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
      setState(() {
        _searchResults = _searchResults.where((u) {
          return FriendService.friendIdFromMap(u) != userId;
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : e.toString().replaceAll('ApiException: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _openChat(String friendId, String friendName) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/chat',
      arguments: {'userId': friendId, 'name': friendName},
    );
  }

  void _openPosts(String friendId, String friendName) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/friend_posts',
      arguments: {'userId': friendId, 'name': friendName},
    );
  }

  Future<void> _confirmRemove(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove friend'),
        content: Text('Remove $name from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await FriendService.removeFriend(id);
      await _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  bool get _showSearchPanel =>
      _searchController.text.trim().length >= 2;

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
            tooltip: 'Friend requests',
            onPressed: () async {
              await Navigator.of(context, rootNavigator: true)
                  .pushNamed('/friend_requests');
              await _loadPendingRequestCount();
            },
            icon: Badge(
              isLabelVisible: _pendingRequestCount > 0,
              label: Text(
                _pendingRequestCount > 9
                    ? '9+'
                    : '$_pendingRequestCount',
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
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
              onRefresh: _refreshAll,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: _onSearchTextChanged,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search by name or email',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: AppColors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppColors.secondary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchTextChanged('');
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type at least 2 characters. People already in your list are hidden.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                          if (_pendingRequestCount > 0) ...[
                            const SizedBox(height: 12),
                            Material(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.of(context, rootNavigator: true)
                                      .pushNamed('/friend_requests');
                                  await _loadPendingRequestCount();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.mail_outline,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _pendingRequestCount == 1
                                              ? '1 person wants to connect'
                                              : '$_pendingRequestCount people want to connect',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textLight,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_showSearchPanel) ...[
                    if (_searchLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (_searchError != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _searchError!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_searchResults.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _friendIds.isEmpty
                                ? 'No new people match that search.'
                                : 'No new people match (everyone listed may already be your friend).',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final u = _searchResults[index];
                            final name = u is Map
                                ? (u['name']?.toString() ?? 'Unknown')
                                : 'Unknown';
                            final email = u is Map
                                ? (u['email']?.toString() ?? '')
                                : '';
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Card(
                                child: ListTile(
                                  title: Text(name),
                                  subtitle: email.isNotEmpty
                                      ? Text(email)
                                      : null,
                                  trailing: FilledButton.tonal(
                                    onPressed: () => _sendRequest(u),
                                    child: const Text('Add'),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _searchResults.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Your friends',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!_showSearchPanel && _friends.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 56,
                              color: AppColors.textLight.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No friends yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Search above to find people by name or email and tap Add.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_friends.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Text(
                          'No friends yet — add someone from the search results above.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        _showSearchPanel ? 0 : 8,
                        16,
                        120,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final f = _friends[index];
                            final name = f is Map
                                ? (f['name']?.toString() ?? 'Unknown')
                                : 'Unknown';
                            final email = f is Map
                                ? (f['email']?.toString() ?? '')
                                : '';
                            final id = FriendService.friendIdFromMap(f);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(name),
                                  subtitle:
                                      email.isNotEmpty ? Text(email) : null,
                                  onTap: id.isEmpty
                                      ? null
                                      : () => _openPosts(id, name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.article_outlined,
                                        ),
                                        tooltip: 'Posts',
                                        onPressed: id.isEmpty
                                            ? null
                                            : () => _openPosts(id, name),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.message_outlined),
                                        tooltip: 'Message',
                                        onPressed: id.isEmpty
                                            ? null
                                            : () => _openChat(id, name),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.person_remove_outlined,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Remove',
                                        onPressed: id.isEmpty
                                            ? null
                                            : () => _confirmRemove(id, name),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _friends.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
