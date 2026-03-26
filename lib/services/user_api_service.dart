import '../models/user_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class UserApiService {
  // Get user profile
  static Future<UserModel> getProfile() async {
    final response = await ApiService.get(
      ApiConfig.usersProfile,
      requireAuth: true,
    );

    return UserModel.fromJson(response['user']);
  }

  // Update user profile
  static Future<UserModel> updateProfile({
    String? name,
    String? dietType,
    Map<String, dynamic>? preferences,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (dietType != null) body['dietType'] = dietType;
    if (preferences != null) body['preferences'] = preferences;

    final response = await ApiService.put(
      ApiConfig.usersProfile,
      body,
      requireAuth: true,
    );

    return UserModel.fromJson(response['user']);
  }

  // Complete onboarding
  static Future<UserModel> completeOnboarding({
    String? dietType,
    Map<String, dynamic>? preferences,
  }) async {
    final body = <String, dynamic>{};
    if (dietType != null) body['dietType'] = dietType;
    if (preferences != null) body['preferences'] = preferences;

    final response = await ApiService.post(
      ApiConfig.usersOnboarding,
      body,
      requireAuth: true,
    );

    return UserModel.fromJson(response['user']);
  }
}
