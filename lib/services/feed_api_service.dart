import '../config/api_config.dart';
import '../models/feed_models.dart';
import '../models/meal_model.dart';
import 'api_service.dart';

class FeedPayload {
  FeedPayload({
    required this.mealType,
    required this.sections,
    required this.quickDecide,
    this.streakHint = 0,
    this.myRatings = const {},
  });

  final String mealType;
  final List<FeedSectionModel> sections;
  final List<MealModel> quickDecide;
  final int streakHint;
  final Map<String, int> myRatings;
}

class FeedApiService {
  static Future<FeedPayload> getFeed() async {
    final response = await ApiService.get(ApiConfig.feed, requireAuth: true);

    if (response['success'] != true) {
      throw Exception(response['message']?.toString() ?? 'Feed failed');
    }

    final sectionsRaw = response['sections'] as List<dynamic>? ?? [];
    final sections = sectionsRaw
        .map((e) => FeedSectionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final qd = response['quickDecide'] as List<dynamic>? ?? [];
    final quickDecide = qd
        .map((e) => MealModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final ratingsRaw = response['myRatings'];
    final Map<String, int> myRatings = {};
    if (ratingsRaw is Map) {
      ratingsRaw.forEach((k, v) {
        myRatings[k.toString()] = (v as num).toInt();
      });
    }

    return FeedPayload(
      mealType: response['mealType']?.toString() ?? '',
      sections: sections,
      quickDecide: quickDecide,
      streakHint: (response['streakHint'] as num?)?.toInt() ?? 0,
      myRatings: myRatings,
    );
  }
}
