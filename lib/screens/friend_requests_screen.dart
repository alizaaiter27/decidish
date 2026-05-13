import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/friend_service.dart';
import 'package:decidish/l10n/app_strings.dart';
import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  List<dynamic> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final reqs = await FriendService.getIncomingRequests();
      if (mounted) {
        setState(() {
          _requests = reqs;
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

  Future<void> _accept(String id) async {
    try {
      await FriendService.acceptRequest(id);
      await _loadRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).friendRequestAccepted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).genericError('$e'))),
      );
    }
  }

  Future<void> _decline(String id) async {
    try {
      await FriendService.declineRequest(id);
      await _loadRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).friendRequestDeclined)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).genericError('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.friendRequests),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _requests.isEmpty
          ? Center(child: Text(strings.noIncomingRequests))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                final from = req['from'];
                return Card(
                  child: ListTile(
                    title: Text(
                      from != null
                          ? from['name'] ?? strings.unknownUserName()
                          : strings.unknownUserName(),
                    ),
                    subtitle: Text(from != null ? from['email'] ?? '' : ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            final id = req['_id'] ?? req['id'];
                            if (id != null) _accept(id.toString());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            final id = req['_id'] ?? req['id'];
                            if (id != null) _decline(id.toString());
                          },
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
