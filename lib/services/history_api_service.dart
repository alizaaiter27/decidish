import '../services/api_service.dart';
import '../config/api_config.dart';

class HistoryApiService {
  /// Records that the user tried this meal (server adds a history row).
  static Future<bool> addMealToHistory(String mealId) async {
    final response = await ApiService.post(
      ApiConfig.history,
      {'mealId': mealId},
      requireAuth: true,
    );
    return response['success'] == true;
  }

  // Get meal history
  static Future<List<Map<String, dynamic>>> getHistory({
    int limit = 50,
    int page = 1,
  }) async {
    final response = await ApiService.get(
      '${ApiConfig.history}?limit=$limit&page=$page',
      requireAuth: true,
    );

    if (response['success'] == true && response['history'] != null) {
      return List<Map<String, dynamic>>.from(response['history']);
    }

    return [];
  }

  // Get history statistics
  static Future<Map<String, dynamic>> getHistoryStats() async {
    final response = await ApiService.get(
      '${ApiConfig.history}/stats',
      requireAuth: true,
    );

    if (response['success'] == true && response['stats'] != null) {
      return response['stats'];
    }

    return {};
  }

  // Update history entry
  static Future<bool> updateHistoryEntry({
    required String historyId,
    int? rating,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (notes != null) body['notes'] = notes;

    final response = await ApiService.put(
      '${ApiConfig.history}/$historyId',
      body,
      requireAuth: true,
    );

    return response['success'] == true;
  }

  // Clear all history
  static Future<Map<String, dynamic>> clearHistory() async {
    final response = await ApiService.delete(
      ApiConfig.history,
      requireAuth: true,
    );

    return response;
  }
}
