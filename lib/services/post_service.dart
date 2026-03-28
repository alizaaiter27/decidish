import 'package:decidish/config/api_config.dart';
import 'package:decidish/services/api_service.dart';

class PostService {
  static Future<List<dynamic>> getPosts() async {
    final res = await ApiService.get(ApiConfig.posts, requireAuth: true);
    final raw = res['posts'];
    if (raw is! List) return [];
    return List<dynamic>.from(raw);
  }

  /// Posts from a friend (server enforces friendship).
  static Future<List<dynamic>> getPostsForFriend(String userId) async {
    final res = await ApiService.get(
      '${ApiConfig.posts}/user/$userId',
      requireAuth: true,
    );
    final raw = res['posts'];
    if (raw is! List) return [];
    return List<dynamic>.from(raw);
  }

  static Future<Map<String, dynamic>> createPost(
    String content, {
    String? mealId,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (mealId != null && mealId.isNotEmpty) {
      body['mealId'] = mealId;
    }
    final res = await ApiService.post(ApiConfig.posts, body, requireAuth: true);
    return Map<String, dynamic>.from(res['post'] as Map);
  }

  static Future<Map<String, dynamic>> likePost(String postId) async {
    final res = await ApiService.post(
      '${ApiConfig.posts}/$postId/like',
      {},
      requireAuth: true,
    );
    return Map<String, dynamic>.from(res);
  }

  static Future<Map<String, dynamic>> unlikePost(String postId) async {
    final res = await ApiService.delete(
      '${ApiConfig.posts}/$postId/like',
      requireAuth: true,
    );
    return Map<String, dynamic>.from(res);
  }
}
