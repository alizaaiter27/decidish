import 'package:decidish/services/api_service.dart';

class FriendService {
  // Send a friend request
  static Future<Map<String, dynamic>> sendRequest(String toUserId) async {
    final res = await ApiService.post('/api/friends/request', {
      'toUserId': toUserId,
    }, requireAuth: true);
    return res;
  }

  // Get incoming requests
  static Future<List<dynamic>> getIncomingRequests() async {
    final res = await ApiService.get(
      '/api/friends/requests',
      requireAuth: true,
    );
    return res['requests'] as List<dynamic>;
  }

  // Accept a request
  static Future<bool> acceptRequest(String requestId) async {
    final res = await ApiService.post(
      '/api/friends/request/$requestId/accept',
      {},
      requireAuth: true,
    );
    return res['success'] == true;
  }

  // Decline a request
  static Future<bool> declineRequest(String requestId) async {
    final res = await ApiService.post(
      '/api/friends/request/$requestId/decline',
      {},
      requireAuth: true,
    );
    return res['success'] == true;
  }

  // Get friends list
  static Future<List<dynamic>> getFriends() async {
    final res = await ApiService.get('/api/friends', requireAuth: true);
    return res['friends'] as List<dynamic>;
  }

  // Remove friend
  static Future<bool> removeFriend(String friendId) async {
    final res = await ApiService.delete(
      '/api/friends/$friendId',
      requireAuth: true,
    );
    return res['success'] == true;
  }

  // Search users by name or email
  static Future<List<dynamic>> searchUsers(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final res = await ApiService.get(
      '/api/users/search?q=$encoded',
      requireAuth: true,
    );
    return res['users'] as List<dynamic>;
  }
}
