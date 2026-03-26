import '../config/api_config.dart';
import '../services/api_service.dart';

class StreakModel {
  final int current;
  final int longest;
  final DateTime? lastCheckIn;
  final List<DateTime> checkInDates;

  StreakModel({
    required this.current,
    required this.longest,
    this.lastCheckIn,
    required this.checkInDates,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      current: json['current'] ?? 0,
      longest: json['longest'] ?? 0,
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'])
          : null,
      checkInDates:
          (json['checkInDates'] as List<dynamic>?)
              ?.map((date) => DateTime.parse(date))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'longest': longest,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'checkInDates': checkInDates
          .map((date) => date.toIso8601String())
          .toList(),
    };
  }

  // Check if user can check in today (hasn't checked in yet)
  bool get canCheckInToday {
    if (lastCheckIn == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckInDate = DateTime(
      lastCheckIn!.year,
      lastCheckIn!.month,
      lastCheckIn!.day,
    );

    return lastCheckInDate.isBefore(today);
  }

  // Get streak display text
  String get streakDisplayText {
    if (current == 0) return 'Start your streak!';
    if (current == 1) return '1 day streak!';
    return '$current days streak!';
  }

  // Get motivational message based on streak
  String get motivationalMessage {
    if (current == 0) return 'Check in daily to build your streak!';
    if (current == 1) return 'Great start! Keep it going!';
    if (current < 7) return 'You\'re on a roll!';
    if (current < 30) return 'Impressive dedication!';
    if (current < 100) return 'Amazing consistency!';
    return 'You\'re a legend! 🔥';
  }
}

class StreakApiService {
  // Daily check-in
  static Future<StreakModel> checkIn() async {
    final response = await ApiService.post(
      ApiConfig.usersCheckin,
      {},
      requireAuth: true,
    );

    return StreakModel.fromJson(response['streak']);
  }

  // Get streak information
  static Future<StreakModel> getStreak() async {
    final response = await ApiService.get(
      ApiConfig.usersStreak,
      requireAuth: true,
    );

    return StreakModel.fromJson(response['streak']);
  }

  // Check if streak is maintained (for home screen auto-check-in)
  static Future<StreakModel> maintainStreak() async {
    try {
      final streak = await getStreak();

      // If it's a new day and user hasn't checked in, auto check-in
      if (streak.canCheckInToday) {
        return await checkIn();
      }

      return streak;
    } catch (e) {
      // Return empty streak on error
      return StreakModel(current: 0, longest: 0, checkInDates: []);
    }
  }
}
