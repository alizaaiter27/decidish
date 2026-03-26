import '../models/meal_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class FavoritesApiService {
  // Get all favorites
  static Future<List<MealModel>> getFavorites() async {
    final response = await ApiService.get(
      ApiConfig.favorites,
      requireAuth: true,
    );

    if (response['success'] == true && response['favorites'] != null) {
      final favs = response['favorites'] as List;
      final List<MealModel> meals = [];
      for (final fav in favs) {
        try {
          if (fav == null) continue;
          final mealJson = fav['meal'];
          if (mealJson == null) continue; // skip deleted or missing meals
          meals.add(MealModel.fromJson(Map<String, dynamic>.from(mealJson)));
        } catch (_) {
          // skip any malformed entries
          continue;
        }
      }
      return meals;
    }

    return [];
  }

  // Add meal to favorites
  static Future<bool> addFavorite(String mealId) async {
    final response = await ApiService.post(ApiConfig.favorites, {
      'mealId': mealId,
    }, requireAuth: true);

    return response['success'] == true;
  }

  // Remove favorite
  static Future<bool> removeFavorite(String favoriteId) async {
    final response = await ApiService.delete(
      '${ApiConfig.favorites}/$favoriteId',
      requireAuth: true,
    );

    return response['success'] == true;
  }

  // Remove favorite by meal ID
  static Future<bool> removeFavoriteByMealId(String mealId) async {
    final response = await ApiService.delete(
      '${ApiConfig.favorites}/meal/$mealId',
      requireAuth: true,
    );

    return response['success'] == true;
  }
}
