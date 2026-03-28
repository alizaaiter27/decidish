import 'package:decidish/config/api_config.dart';
import 'package:decidish/services/api_service.dart';

class FriendService {
  // Send a friend request
  static Future<Map<String, dynamic>> sendRequest(String toUserId) async {
    final res = await ApiService.post(
      '${ApiConfig.friends}/request',
      {'toUserId': toUserId},
      requireAuth: true,
    );
    return res;
  }

  // Get incoming requests
  static Future<List<dynamic>> getIncomingRequests() async {
    final res = await ApiService.get(
      '${ApiConfig.friends}/requests',
      requireAuth: true,
    );
    final raw = res['requests'];
    if (raw is! List) return [];
    return List<dynamic>.from(raw);
  }

  // Accept a request
  static Future<bool> acceptRequest(String requestId) async {
    final res = await ApiService.post(
      '${ApiConfig.friends}/request/$requestId/accept',
      {},
      requireAuth: true,
    );
    return res['success'] == true;
  }

  // Decline a request
  static Future<bool> declineRequest(String requestId) async {
    final res = await ApiService.post(
      '${ApiConfig.friends}/request/$requestId/decline',
      {},
      requireAuth: true,
    );
    return res['success'] == true;
  }

  // Get friends list
  static Future<List<dynamic>> getFriends() async {
    final res = await ApiService.get(ApiConfig.friends, requireAuth: true);
    final raw = res['friends'];
    if (raw is! List) return [];
    return List<dynamic>.from(raw);
  }

  // Remove friend
  static Future<bool> removeFriend(String friendId) async {
    final res = await ApiService.delete(
      '${ApiConfig.friends}/$friendId',
      requireAuth: true,
    );
    return res['success'] == true;
  }

  // Search users by name or email
  static Future<List<dynamic>> searchUsers(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final res = await ApiService.get(
      '${ApiConfig.usersSearch}?q=$encoded',
      requireAuth: true,
    );
    final raw = res['users'];
    if (raw is! List) return [];
    return List<dynamic>.from(raw);
  }

  static String friendIdFromMap(dynamic f) {
    if (f is! Map) return '';
    final m = Map<String, dynamic>.from(f);
    final v = m['_id'] ?? m['id'];
    return v?.toString() ?? '';
  }
}
