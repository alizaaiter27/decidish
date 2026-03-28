import 'package:decidish/config/api_config.dart';
import 'package:decidish/services/api_service.dart';

class MessageService {
  // Send a message to a friend
  static Future<Map<String, dynamic>> sendMessage(
    String toUserId,
    String content,
  ) async {
    final res = await ApiService.post(
      ApiConfig.messages,
      {'toUserId': toUserId, 'content': content},
      requireAuth: true,
    );
    return res;
  }

  // Get messages between current user and another
  static Future<List<dynamic>> getMessages(String userId) async {
    final res = await ApiService.get(
      '${ApiConfig.messages}/$userId',
      requireAuth: true,
    );
    final raw = res['messages'];
    if (raw is! List) return [];
    return List<dynamic>.from(raw);
  }
}
