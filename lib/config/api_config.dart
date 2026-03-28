import 'dart:io';

class ApiConfig {
  // Automatically detect the correct base URL based on platform
  static String get baseUrl {
    // For Android emulator, use 10.0.2.2 (special IP that maps to host machine's localhost)
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    // For iOS simulator and other platforms, use localhost
    return 'http://localhost:3000';
  }

  // If you're testing on a physical device, uncomment and set your computer's IP:
  // static const String baseUrl = 'http://192.168.1.XXX:3000'; // Replace XXX with your IP

  static const String apiPrefix = '/api';

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  // Endpoints
  static const String health = '/health';
  static const String authSignup = '/auth/signup';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authPassword = '/auth/password';
  static const String usersProfile = '/users/profile';
  static const String usersOnboarding = '/users/onboarding';
  static const String usersCheckin = '/users/checkin';
  static const String usersStreak = '/users/streak';
  static const String usersSurveyPick = '/users/survey-pick';
  static const String meals = '/meals';
  static const String recommendations = '/recommendations';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String feed = '/feed';
  static const String posts = '/posts';
  static const String friends = '/friends';
  static const String messages = '/messages';
  static const String usersSearch = '/users/search';
}
