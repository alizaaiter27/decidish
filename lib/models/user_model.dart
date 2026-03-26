import '../services/streak_api_service.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? dietType;
  final Map<String, dynamic>? preferences;
  final bool onboardingCompleted;
  final StreakModel? streak;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.dietType,
    this.preferences,
    required this.onboardingCompleted,
    this.streak,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      dietType: json['dietType'],
      preferences: json['preferences'],
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      streak: json['streak'] != null
          ? StreakModel.fromJson(json['streak'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'dietType': dietType,
      'preferences': preferences,
      'onboardingCompleted': onboardingCompleted,
      'streak': streak?.toJson(),
    };
  }
}
