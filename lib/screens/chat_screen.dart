import 'package:flutter/material.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/message_service.dart';
import 'package:decidish/services/user_api_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  final TextEditingController _controller = TextEditingController();
  String? _friendId;
  String _friendName = '';
  String? _currentUserId;
  final ScrollController _scrollController = ScrollController();
  bool _parsedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parsedArgs) return;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;
    _parsedArgs = true;
    _friendId = args['userId']?.toString();
    _friendName = args['name']?.toString() ?? '';
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    try {
      final profile = await UserApiService.getProfile();
      _currentUserId = profile.id;
    } catch (e) {
      // ignore and proceed; messages will show neutral
    }
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (_friendId == null) return;
    setState(() => _loading = true);
    try {
      final msgs = await MessageService.getMessages(_friendId!);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
        // scroll to bottom after a tiny delay to ensure list built
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _friendId == null) return;
    try {
      await MessageService.sendMessage(_friendId!, text);
      _controller.clear();
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    try {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).maybePop();
          },
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(_friendName.isNotEmpty ? _friendName : 'Chat'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final content = m['content'] ?? '';
                      final senderId =
                          m['sender'] ?? m['senderId'] ?? m['from'];
                      final createdAtRaw =
                          m['createdAt'] ?? m['created_at'] ?? m['updatedAt'];
                      DateTime? createdAt;
                      if (createdAtRaw != null) {
                        try {
                          createdAt = DateTime.parse(createdAtRaw.toString());
                        } catch (_) {
                          createdAt = null;
                        }
                      }
                      final isMe =
                          _currentUserId != null &&
                          senderId != null &&
                          senderId.toString() == _currentUserId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 2),
                                  bottomRight: Radius.circular(isMe ? 2 : 12),
                                ),
                              ),
                              child: Text(
                                content,
                                style: TextStyle(
                                  color: isMe
                                      ? AppColors.white
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                            if (createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  DateFormat(
                                    'h:mm a',
                                  ).format(createdAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
