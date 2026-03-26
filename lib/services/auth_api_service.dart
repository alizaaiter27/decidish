import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class AuthApiService {
  // Sign up
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(ApiConfig.authSignup, {
      'name': name,
      'email': email,
      'password': password,
    });

    if (response['success'] == true && response['token'] != null) {
      await AuthService.saveToken(response['token']);
      if (response['user'] != null) {
        await AuthService.saveUser(
          Map<String, dynamic>.from(response['user'] as Map),
        );
      }
    }

    return response;
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(ApiConfig.authLogin, {
      'email': email,
      'password': password,
    });

    if (response['success'] == true && response['token'] != null) {
      await AuthService.saveToken(response['token']);
      if (response['user'] != null) {
        await AuthService.saveUser(
          Map<String, dynamic>.from(response['user'] as Map),
        );
      }
    }

    return response;
  }

  // Get current user
  static Future<UserModel> getCurrentUser() async {
    final response = await ApiService.get(ApiConfig.authMe, requireAuth: true);

    final user = UserModel.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
    await AuthService.saveUser(
      Map<String, dynamic>.from(response['user'] as Map),
    );
    return user;
  }

  /// Updates password and rotates JWT (new token returned by API).
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await ApiService.put(
      ApiConfig.authPassword,
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      requireAuth: true,
    );
    if (response['success'] == true && response['token'] != null) {
      await AuthService.saveToken(response['token'] as String);
    }
  }

  // Logout
  static Future<void> logout() async {
    await AuthService.clearAuth();
  }
}
