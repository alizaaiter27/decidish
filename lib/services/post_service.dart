import 'package:decidish/config/api_config.dart';
import 'package:decidish/services/api_service.dart';

class PostService {
  static Future<List<dynamic>> getPosts() async {
    final res = await ApiService.get(ApiConfig.posts, requireAuth: true);
    return res['posts'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createPost(String content) async {
    final res = await ApiService.post(ApiConfig.posts, {
      'content': content,
    }, requireAuth: true);
    return res['post'] as Map<String, dynamic>;
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
