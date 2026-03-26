import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/models/meal_model.dart';
import 'package:decidish/services/favorites_api_service.dart';
import 'package:decidish/services/meal_api_service.dart';
import 'package:decidish/widgets/meal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  MealModel? _meal;
  bool _isFavorite = false;
  bool _isAddingFavorite = false;
  bool _hasLoadedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedArgs) {
      _loadMealFromArguments();
      _hasLoadedArgs = true;
    }
  }

  void _loadMealFromArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MealModel) {
      setState(() {
        _meal = args;
      });
      _checkIfFavorite();
      _hydrateMealIfNeeded();
    }
  }

  /// Fetches full document from API when navigation only passed a thin payload.
  Future<void> _hydrateMealIfNeeded() async {
    final m = _meal;
    if (m == null || m.id.isEmpty) return;
    final missingRecipe =
        (m.description == null || m.description!.trim().isEmpty) &&
        (m.ingredients == null || m.ingredients!.isEmpty);
    final missingUrls =
        (m.recipeSourceUrl == null || m.recipeSourceUrl!.trim().isEmpty) &&
        (m.recipeVideoUrl == null || m.recipeVideoUrl!.trim().isEmpty);
    if (!missingRecipe && !missingUrls) return;
    try {
      final full = await MealApiService.getMealById(m.id);
      if (!mounted || full == null) return;
      setState(() => _meal = full);
    } catch (_) {}
  }

  /// Recipe APIs often omit the scheme (`www…`, `youtu.be/…`); [Uri.tryParse] then has no scheme and would not open.
  static Uri? _normalizeLaunchUri(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final first = Uri.tryParse(t);
    if (first != null &&
        first.hasScheme &&
        first.scheme != 'http' &&
        first.scheme != 'https') {
      return first;
    }
    if (first != null && first.hasScheme) {
      return first;
    }
    if (t.startsWith('//')) {
      return Uri.tryParse('https:$t');
    }
    final lower = t.toLowerCase();
    if (lower.startsWith('mailto:') || lower.startsWith('tel:')) {
      return Uri.tryParse(t);
    }
    return Uri.tryParse('https://$t');
  }

  Future<void> _openExternalUrl(String? raw) async {
    if (raw == null || raw.trim().isEmpty) return;
    final uri = _normalizeLaunchUri(raw);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link')),
        );
      }
      return;
    }
    try {
      if (!await canLaunchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this link on this device')),
          );
        }
        return;
      }
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _checkIfFavorite() async {
    if (_meal == null) return;
    try {
      final favorites = await FavoritesApiService.getFavorites();
      setState(() {
        _isFavorite = favorites.any((fav) => fav.id == _meal!.id);
      });
    } catch (_) {
      // Silently fail - user can still add/remove favorites
    }
  }

  Future<void> _toggleFavorite() async {
    if (_meal == null || _isAddingFavorite) return;

    setState(() => _isAddingFavorite = true);

    try {
      if (_isFavorite) {
        await FavoritesApiService.removeFavoriteByMealId(_meal!.id);
        setState(() => _isFavorite = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        await FavoritesApiService.addFavorite(_meal!.id);
        setState(() => _isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('ApiException: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingFavorite = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No meal passed in navigation
    if (_meal == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            'Recommendation',
            style: TextStyle(color: AppColors.textDark),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No meal data available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try going back and requesting a new recommendation.',
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final meal = _meal!;
    final mealName = meal.name;
    final recipeBody = MealModel.normalizeRecipeText(meal.description);
    final calories = meal.nutrition.calories;
    final protein = meal.nutrition.protein;
    final carbs = meal.nutrition.carbs;
    final fat = meal.nutrition.fat;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Recommendation',
          style: TextStyle(color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Your Meal',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on your preferences',
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MealNetworkImage(
                        imageUrl: meal.imageUrl,
                        height: 240,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(24),
                        iconSize: 72,
                      ),
                      if (meal.cuisine != null && meal.cuisine!.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: AppColors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.public,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    meal.cuisine!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meal Name
              Text(
                mealName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              if (meal.dietTypes != null && meal.dietTypes!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: meal.dietTypes!
                      .map(
                        (diet) => Chip(
                          label: Text(
                            diet,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor:
                              AppColors.secondary.withValues(alpha: 0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              if (meal.mealType != null) ...[
                const SizedBox(height: 8),
                Text(
                  meal.mealType!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Nutrition section
              const Text(
                'Nutrition Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildNutritionCard('Calories', '$calories', 'kcal'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutritionCard(
                      'Protein',
                      '${protein}g',
                      'grams',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNutritionCard('Carbs', '${carbs}g', 'grams'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutritionCard('Fat', '${fat}g', 'grams'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (meal.displayIngredientLines.isNotEmpty) ...[
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                ...meal.displayIngredientLines.map(
                  (ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.fiber_manual_record,
                            size: 8,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ing,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text(
                'Recipe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                recipeBody.isNotEmpty
                    ? recipeBody
                    : 'No written steps for this dish yet. Open the original recipe link below if available.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
              if ((meal.recipeSourceUrl != null &&
                      meal.recipeSourceUrl!.trim().isNotEmpty) ||
                  (meal.recipeVideoUrl != null &&
                      meal.recipeVideoUrl!.trim().isNotEmpty)) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (meal.recipeSourceUrl != null &&
                        meal.recipeSourceUrl!.trim().isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openExternalUrl(meal.recipeSourceUrl),
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Original recipe'),
                      ),
                    if (meal.recipeVideoUrl != null &&
                        meal.recipeVideoUrl!.trim().isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openExternalUrl(meal.recipeVideoUrl),
                        icon: const Icon(Icons.play_circle_outline, size: 20),
                        label: const Text('Watch video'),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAddingFavorite ? null : _toggleFavorite,
                      icon: _isAddingFavorite
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                            ),
                      label: Text(
                        _isAddingFavorite
                            ? 'Updating...'
                            : (_isFavorite ? 'Favorited' : 'Favorite'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isFavorite
                            ? AppColors.error
                            : AppColors.primary,
                        side: BorderSide(
                          color: _isFavorite
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Go back so user can ask for another recommendation
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(
                        'Try Again',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
