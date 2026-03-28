import 'dart:async';

import 'package:flutter/material.dart';
import 'package:decidish/services/api_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/friend_service.dart';

/// Same search as [FriendsScreen] inline search; kept for direct navigation.
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    final q = _queryController.text.trim();
    setState(() {});
    if (q.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search());
  }

  Future<void> _search() async {
    final q = _queryController.text.trim();
    if (q.length < 2) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await FriendService.searchUsers(q);
      if (mounted) {
        setState(() {
          _results = res;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      setState(() {
        _results = _results.where((u) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or email (min. 2 characters)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _queryController.clear();
                          _onChanged('');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Results update as you type.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final u = _results[index];
                  final name = u is Map
                      ? (u['name']?.toString() ?? 'Unknown')
                      : 'Unknown';
                  final email =
                      u is Map ? (u['email']?.toString() ?? '') : '';
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: FilledButton.tonal(
                        onPressed: () => _sendRequest(u),
                        child: const Text('Add'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
