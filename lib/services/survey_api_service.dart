import '../config/api_config.dart';
import '../models/meal_model.dart';
import 'api_service.dart';

/// Quick "Help me decide" survey — home-cooked meals only (API uses your meal DB).
class SurveyApiService {
  static Future<List<MealModel>> submitSurvey({
    required String mood,
    required String mealType,
    required String budgetTier,
    required String portion,
    required String timeFeeling,
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.meals}/survey',
      {
        'mood': mood,
        'mealType': mealType,
        'budgetTier': budgetTier,
        'portion': portion,
        'timeFeeling': timeFeeling,
      },
      requireAuth: true,
    );
    if (response['success'] == true && response['meals'] != null) {
      return (response['meals'] as List)
          .map((e) => MealModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  /// Call when the user opens a suggestion — improves future survey ranking.
  static Future<void> recordPick({
    required String mealId,
    required String mood,
    required String mealType,
    required String budgetTier,
    required String portion,
    required String timeFeeling,
  }) async {
    await ApiService.post(
      ApiConfig.usersSurveyPick,
      {
        'mealId': mealId,
        'mood': mood,
        'mealType': mealType,
        'budgetTier': budgetTier,
        'portion': portion,
        'timeFeeling': timeFeeling,
      },
      requireAuth: true,
    );
  }
}
