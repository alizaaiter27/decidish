class MealModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final Nutrition nutrition;
  final List<String>? dietTypes;
  final String? cuisine;
  final List<String>? ingredients;
  /// Amount + name lines when present (e.g. TheMealDB import); preferred for display.
  final List<String>? ingredientLines;
  final List<String>? tags;
  final int? preparationTime;
  /// Approximate cost (same unit as backend `estimatedCost`, e.g. USD).
  final num? estimatedCost;
  final String? difficulty;
  final String? mealType;
  final TasteProfile? tasteProfile;
  final List<String>? cookingMethod;
  final List<String>? seasonality;
  final Complexity? complexity;

  /// Server-side compatibility score (higher = better match). Present on `/meals/personalized`.
  final double? compatibilityScore;
  final Map<String, dynamic>? scoreBreakdown;

  /// Present on `POST /meals/pantry` — how well the meal fits what you have at home.
  final PantryMatchInfo? pantryMatch;

  final String? recipeSourceUrl;
  final String? recipeVideoUrl;

  MealModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.nutrition,
    this.dietTypes,
    this.cuisine,
    this.ingredients,
    this.ingredientLines,
    this.tags,
    this.preparationTime,
    this.estimatedCost,
    this.difficulty,
    this.mealType,
    this.tasteProfile,
    this.cookingMethod,
    this.seasonality,
    this.complexity,
    this.compatibilityScore,
    this.scoreBreakdown,
    this.pantryMatch,
    this.recipeSourceUrl,
    this.recipeVideoUrl,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
      dietTypes: json['dietTypes'] != null
          ? List<String>.from(json['dietTypes'])
          : null,
      cuisine: json['cuisine'],
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : null,
      ingredientLines: json['ingredientLines'] != null
          ? List<String>.from(json['ingredientLines'])
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      preparationTime: json['preparationTime'],
      estimatedCost: json['estimatedCost'] as num?,
      difficulty: json['difficulty'],
      mealType: json['mealType'],
      tasteProfile: json['tasteProfile'] != null
          ? TasteProfile.fromJson(json['tasteProfile'])
          : null,
      cookingMethod: json['cookingMethod'] != null
          ? List<String>.from(json['cookingMethod'])
          : null,
      seasonality: json['seasonality'] != null
          ? List<String>.from(json['seasonality'])
          : null,
      complexity: json['complexity'] != null
          ? Complexity.fromJson(json['complexity'])
          : null,
      compatibilityScore: (json['compatibilityScore'] as num?)?.toDouble(),
      scoreBreakdown: json['scoreBreakdown'] != null
          ? Map<String, dynamic>.from(json['scoreBreakdown'] as Map)
          : null,
      pantryMatch: json['pantryMatch'] != null
          ? PantryMatchInfo.fromJson(
              Map<String, dynamic>.from(json['pantryMatch'] as Map),
            )
          : null,
      recipeSourceUrl: json['recipeSourceUrl'] as String?,
      recipeVideoUrl: json['recipeVideoUrl'] as String?,
    );
  }

  /// Ingredients to show in UI: lines with amounts when available.
  List<String> get displayIngredientLines {
    if (ingredientLines != null && ingredientLines!.isNotEmpty) {
      return ingredientLines!;
    }
    return ingredients ?? const [];
  }

  /// Normalizes line breaks from API / DB (Windows `\r\n`) for display.
  static String normalizeRecipeText(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'nutrition': nutrition.toJson(),
      'dietTypes': dietTypes,
      'cuisine': cuisine,
      'ingredients': ingredients,
      'ingredientLines': ingredientLines,
      'tags': tags,
      'preparationTime': preparationTime,
      'estimatedCost': estimatedCost,
      'difficulty': difficulty,
      'mealType': mealType,
      'tasteProfile': tasteProfile?.toJson(),
      'cookingMethod': cookingMethod,
      'seasonality': seasonality,
      'complexity': complexity?.toJson(),
      'compatibilityScore': compatibilityScore,
      'scoreBreakdown': scoreBreakdown,
      'pantryMatch': pantryMatch?.toJson(),
      'recipeSourceUrl': recipeSourceUrl,
      'recipeVideoUrl': recipeVideoUrl,
    };
  }
}

class PantryMatchInfo {
  final int matchedCount;
  final int totalIngredients;
  final double coverage;
  final List<String> missingIngredients;
  final List<String> matchedIngredients;

  PantryMatchInfo({
    required this.matchedCount,
    required this.totalIngredients,
    required this.coverage,
    required this.missingIngredients,
    required this.matchedIngredients,
  });

  factory PantryMatchInfo.fromJson(Map<String, dynamic> json) {
    return PantryMatchInfo(
      matchedCount: (json['matchedCount'] as num?)?.toInt() ?? 0,
      totalIngredients: (json['totalIngredients'] as num?)?.toInt() ?? 0,
      coverage: (json['coverage'] as num?)?.toDouble() ?? 0,
      missingIngredients: json['missingIngredients'] != null
          ? List<String>.from(json['missingIngredients'] as List)
          : const [],
      matchedIngredients: json['matchedIngredients'] != null
          ? List<String>.from(json['matchedIngredients'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchedCount': matchedCount,
      'totalIngredients': totalIngredients,
      'coverage': coverage,
      'missingIngredients': missingIngredients,
      'matchedIngredients': matchedIngredients,
    };
  }

  int get coveragePercent => (coverage * 100).round();
}

class TasteProfile {
  final int sweet;
  final int salty;
  final int spicy;
  final int sour;
  final int bitter;
  final int umami;

  TasteProfile({
    required this.sweet,
    required this.salty,
    required this.spicy,
    required this.sour,
    required this.bitter,
    required this.umami,
  });

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    return TasteProfile(
      sweet: json['sweet'] ?? 0,
      salty: json['salty'] ?? 0,
      spicy: json['spicy'] ?? 0,
      sour: json['sour'] ?? 0,
      bitter: json['bitter'] ?? 0,
      umami: json['umami'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sweet': sweet,
      'salty': salty,
      'spicy': spicy,
      'sour': sour,
      'bitter': bitter,
      'umami': umami,
    };
  }

  String get dominantTaste {
    final tastes = {
      'Sweet': sweet,
      'Salty': salty,
      'Spicy': spicy,
      'Sour': sour,
      'Bitter': bitter,
      'Umami': umami,
    };

    final maxTaste = tastes.entries.reduce((a, b) => a.value > b.value ? a : b);

    return maxTaste.key;
  }

  String get tasteDescription {
    final dominant = dominantTaste;
    final tasteValues = {
      'Sweet': sweet,
      'Salty': salty,
      'Spicy': spicy,
      'Sour': sour,
      'Bitter': bitter,
      'Umami': umami,
    };
    final intensity = tasteValues[dominant] ?? 0;

    if (intensity <= 1) return 'Mild $dominant';
    if (intensity <= 3) return 'Balanced $dominant';
    if (intensity <= 4) return 'Rich $dominant';
    return 'Intense $dominant';
  }
}

class Complexity {
  final int ingredientsCount;
  final int stepsCount;
  final List<String>? specialEquipment;

  Complexity({
    required this.ingredientsCount,
    required this.stepsCount,
    this.specialEquipment,
  });

  factory Complexity.fromJson(Map<String, dynamic> json) {
    return Complexity(
      ingredientsCount: json['ingredientsCount'] ?? 0,
      stepsCount: json['stepsCount'] ?? 0,
      specialEquipment: json['specialEquipment'] != null
          ? List<String>.from(json['specialEquipment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredientsCount': ingredientsCount,
      'stepsCount': stepsCount,
      'specialEquipment': specialEquipment,
    };
  }

  String get complexityLevel {
    if (ingredientsCount <= 5 && stepsCount <= 3) return 'Simple';
    if (ingredientsCount <= 10 && stepsCount <= 6) return 'Moderate';
    return 'Complex';
  }
}

class Nutrition {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
