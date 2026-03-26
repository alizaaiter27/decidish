import 'package:decidish/services/api_service.dart';

class MessageService {
  // Send a message to a friend
  static Future<Map<String, dynamic>> sendMessage(
    String toUserId,
    String content,
  ) async {
    final res = await ApiService.post('/api/messages', {
      'toUserId': toUserId,
      'content': content,
    }, requireAuth: true);
    return res;
  }

  // Get messages between current user and another
  static Future<List<dynamic>> getMessages(String userId) async {
    final res = await ApiService.get(
      '/api/messages/$userId',
      requireAuth: true,
    );
    return res['messages'] as List<dynamic>;
  }
}
