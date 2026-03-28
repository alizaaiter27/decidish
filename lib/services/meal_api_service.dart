import '../models/meal_model.dart';
import '../models/meal_review_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class MealApiService {
  /// TheMealDB area list merged with distinct `cuisine` values in your database.
  static Future<List<String>> getCuisineAreas() async {
    final response = await ApiService.get(
      '${ApiConfig.meals}/cuisine-areas',
      requireAuth: false,
    );
    if (response['success'] == true && response['areas'] != null) {
      return List<String>.from(response['areas'] as List);
    }
    return [];
  }

  /// Ranked by compatibility score (preferences + taste + similarity + popularity).
  static Future<List<MealModel>> getPersonalizedMeals({String? mealType}) async {
    var queryString = '';
    if (mealType != null) {
      queryString = '?mealType=${Uri.encodeComponent(mealType)}';
    }
    final response = await ApiService.get(
      '${ApiConfig.meals}/personalized$queryString',
      requireAuth: true,
    );

    if (response['success'] == true && response['meals'] != null) {
      return (response['meals'] as List)
          .map((meal) => MealModel.fromJson(Map<String, dynamic>.from(meal as Map)))
          .toList();
    }

    return [];
  }

  // Get all meals
  static Future<List<MealModel>> getMeals({
    String? dietType,
    String? cuisine,
    String? search,
  }) async {
    String queryParams = '';
    if (dietType != null) queryParams += '?dietType=$dietType';
    if (cuisine != null) {
      queryParams += queryParams.isEmpty ? '?' : '&';
      queryParams += 'cuisine=$cuisine';
    }
    if (search != null) {
      queryParams += queryParams.isEmpty ? '?' : '&';
      queryParams += 'search=$search';
    }

    final response = await ApiService.get('${ApiConfig.meals}$queryParams');

    if (response['success'] == true && response['meals'] != null) {
      return (response['meals'] as List)
          .map((meal) => MealModel.fromJson(meal))
          .toList();
    }

    return [];
  }

  // Get single meal by ID
  static Future<MealModel?> getMealById(String mealId) async {
    final response = await ApiService.get('${ApiConfig.meals}/$mealId');

    if (response['success'] == true && response['meal'] != null) {
      return MealModel.fromJson(response['meal']);
    }

    return null;
  }

  /// Community ratings + optional written reviews with author names.
  static Future<List<MealReviewItem>> getMealReviews(String mealId) async {
    final response = await ApiService.get(
      '${ApiConfig.meals}/$mealId/reviews',
      requireAuth: false,
    );
    if (response['success'] != true) {
      return [];
    }
    final raw = response['reviews'];
    if (raw is! List) return [];
    return raw
        .map(
          (e) => MealReviewItem.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  /// [saveHistory] when true, server records this pick in meal history (use for "Decide for me" only).
  static Future<MealModel?> getRecommendation({
    String? mealType,
    bool saveHistory = false,
  }) async {
    final params = <String, String>{};
    if (mealType != null) {
      params['mealType'] = mealType;
    }
    if (saveHistory) {
      params['saveHistory'] = 'true';
    }
    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    final endpoint = '${ApiConfig.recommendations}$query';

    final response = await ApiService.get(endpoint, requireAuth: true);

    if (response['success'] == true && response['meal'] != null) {
      final mealMap = Map<String, dynamic>.from(response['meal'] as Map);
      final ctx = response['recommendationContext'];
      if (ctx is Map) {
        final c = Map<String, dynamic>.from(ctx);
        if (c['score'] != null) {
          mealMap['compatibilityScore'] = (c['score'] as num).toDouble();
        }
        if (c['scoreBreakdown'] != null) {
          mealMap['scoreBreakdown'] = c['scoreBreakdown'];
        }
      }
      return MealModel.fromJson(mealMap);
    }

    return null;
  }

  /// Meals ranked by overlap with ingredients you have on hand (`POST /meals/pantry`).
  static Future<List<MealModel>> getMealsFromPantry(List<String> ingredients) async {
    final response = await ApiService.post(
      '${ApiConfig.meals}/pantry',
      {'ingredients': ingredients},
      requireAuth: true,
    );

    if (response['success'] == true && response['meals'] != null) {
      return (response['meals'] as List)
          .map((meal) => MealModel.fromJson(Map<String, dynamic>.from(meal as Map)))
          .toList();
    }

    return [];
  }

  /// Persists a 1–5 star rating for this meal (used from feed).
  /// When [syncReview] is true, sends [review] (may be empty to clear text).
  /// When false, stars-only update leaves any existing written review unchanged.
  ///
  /// When [append] is true, always creates a **new** review row (multiple reviews
  /// per meal). When false (default), updates the user's latest rating for that meal
  /// (feed star taps).
  static Future<void> rateMeal(
    String mealId,
    int rating, {
    String? review,
    bool syncReview = false,
    bool append = false,
  }) async {
    final body = <String, dynamic>{'rating': rating};
    if (syncReview) {
      body['review'] = review ?? '';
    }
    if (append) {
      body['append'] = true;
    }
    await ApiService.post(
      '${ApiConfig.meals}/$mealId/rate',
      body,
      requireAuth: true,
    );
  }

  /// Deletes a specific meal rating row; server allows only the author.
  static Future<void> deleteMealRating(String mealId, String ratingId) async {
    await ApiService.delete(
      '${ApiConfig.meals}/$mealId/ratings/$ratingId',
      requireAuth: true,
    );
  }

  /// Removes the current user's latest rating for this meal (feed: tap same star again).
  static Future<void> removeMyLatestMealRating(String mealId) async {
    await ApiService.delete(
      '${ApiConfig.meals}/$mealId/rate',
      requireAuth: true,
    );
  }
}
