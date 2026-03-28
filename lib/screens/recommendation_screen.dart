import 'dart:async';

import 'package:decidish/services/api_service.dart';
import 'package:decidish/services/auth_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/models/meal_model.dart';
import 'package:decidish/models/meal_review_model.dart';
import 'package:decidish/services/favorites_api_service.dart';
import 'package:decidish/services/history_api_service.dart';
import 'package:decidish/services/meal_api_service.dart';
import 'package:decidish/widgets/meal_network_image.dart';
import 'package:decidish/widgets/meal_review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  static const int _kLatestReviewsPreview = 2;

  MealModel? _meal;
  bool _isFavorite = false;
  bool _isAddingFavorite = false;
  bool _hasLoadedArgs = false;
  List<MealReviewItem> _reviews = [];
  bool _reviewsLoading = false;
  bool _reviewSaving = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _deletingRatingId;
  bool _triedMealSaving = false;
  bool _triedMealRecorded = false;

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
      _loadCurrentUserId();
      _checkIfFavorite();
      _hydrateMealIfNeeded();
      _loadReviewsForCurrentMeal();
    }
  }

  Future<void> _loadCurrentUserId() async {
    final u = await AuthService.getUser();
    if (!mounted) return;
    final id = u?['id']?.toString() ?? u?['_id']?.toString();
    final email = u?['email']?.toString().trim().toLowerCase();
    setState(() {
      _currentUserId = id;
      _currentUserEmail = email;
    });
  }

  bool _isMyReview(MealReviewItem r) {
    if (r.id == null || r.id!.isEmpty) return false;
    final uid = _currentUserId;
    final authorId = r.authorUserId;
    if (uid != null &&
        uid.isNotEmpty &&
        authorId != null &&
        authorId.isNotEmpty &&
        authorId == uid) {
      return true;
    }
    final myEmail = _currentUserEmail;
    if (myEmail != null && myEmail.isNotEmpty) {
      final e = r.authorEmail?.trim().toLowerCase();
      if (e != null && e == myEmail) return true;
    }
    return false;
  }

  Future<void> _confirmDeleteReview(MealReviewItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'This removes your rating and written review for this entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _performDeleteReview(r);
    }
  }

  Future<void> _performDeleteReview(MealReviewItem r) async {
    final meal = _meal;
    final rid = r.id;
    if (meal == null || rid == null || rid.isEmpty) return;

    setState(() => _deletingRatingId = rid);
    try {
      await MealApiService.deleteMealRating(meal.id, rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted')),
      );
      await _loadReviewsForCurrentMeal();
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : 'Could not delete review';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingRatingId = null);
    }
  }

  Future<void> _loadReviewsForCurrentMeal() async {
    final id = _meal?.id;
    if (id == null || id.isEmpty) return;
    setState(() => _reviewsLoading = true);
    try {
      final list = await MealApiService.getMealReviews(id);
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _reviewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _reviewsLoading = false;
      });
    }
  }

  Future<void> _openMealReviewEditor() async {
    final meal = _meal;
    if (meal == null || _reviewSaving) return;

    const initialStars = 3;
    const initialText = '';

    final result = await showModalBottomSheet<(int, String)?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => MealReviewSheet(
        mealName: meal.name,
        initialStars: initialStars,
        initialText: initialText,
      ),
    );

    if (result == null || !mounted) return;
    final saved = result;
    final done = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        done.complete();
        return;
      }
      _saveMealReview(meal, saved.$1, saved.$2).whenComplete(done.complete);
    });
    await done.future;
  }

  Future<void> _saveMealReview(MealModel meal, int stars, String text) async {
    if (_reviewSaving) return;
    setState(() => _reviewSaving = true);
    try {
      await MealApiService.rateMeal(
        meal.id,
        stars,
        review: text,
        syncReview: true,
        append: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved')),
      );
      await _loadReviewsForCurrentMeal();
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : 'Could not save review';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _reviewSaving = false);
    }
  }

  void _openAllReviewsSheet() {
    final meal = _meal;
    if (meal == null || _reviews.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.88;
        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'All reviews · ${meal.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  itemCount: _reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    return _buildReviewTile(
                      _reviews[i],
                      fullReviewText: true,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _recordTriedMeal() async {
    final meal = _meal;
    if (meal == null || _triedMealSaving || _triedMealRecorded) return;

    setState(() => _triedMealSaving = true);
    try {
      final ok = await HistoryApiService.addMealToHistory(meal.id);
      if (!mounted) return;
      if (ok) {
        setState(() => _triedMealRecorded = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to your meal history'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save to history')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Could not save to history',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _triedMealSaving = false);
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: (_triedMealSaving || _triedMealRecorded)
                      ? null
                      : _recordTriedMeal,
                  icon: _triedMealSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _triedMealRecorded
                              ? Icons.check_circle
                              : Icons.restaurant_menu,
                          size: 18,
                        ),
                  label: Text(
                    _triedMealRecorded
                        ? 'Saved to meal history'
                        : 'I tried this meal',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _triedMealRecorded
                        ? AppColors.textLight
                        : AppColors.primary,
                    side: BorderSide(
                      color: _triedMealRecorded
                          ? AppColors.textLight.withValues(alpha: 0.4)
                          : AppColors.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
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

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: (_meal == null || _reviewSaving)
                      ? null
                      : _openMealReviewEditor,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: _reviewSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rate_review_outlined, size: 18),
                  label: Text(
                    _reviewSaving ? 'Saving…' : 'Add review',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Community reviews',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _reviewsLoading ? null : _loadReviewsForCurrentMeal,
                    icon: _reviewsLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh reviews',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ratings and notes from other members',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              if (_reviewsLoading && _reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No reviews yet. Use Add review above or the Feed — you can add more than one review over time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                )
              else ...[
                ..._reviews
                    .take(_kLatestReviewsPreview)
                    .map(
                      (r) => _buildReviewTile(
                        r,
                        fullReviewText: false,
                      ),
                    ),
                if (_reviews.length > _kLatestReviewsPreview)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _openAllReviewsSheet,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        icon: const Icon(Icons.expand_more_rounded, size: 22),
                        label: Text(
                          'View more reviews (${_reviews.length - _kLatestReviewsPreview})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildReviewTile(
    MealReviewItem r, {
    bool fullReviewText = false,
  }) {
    final dateStr = r.updatedAt != null
        ? DateFormat.yMMMd().format(r.updatedAt!.toLocal())
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      r.authorName.isNotEmpty
                          ? r.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (dateStr != null)
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isMyReview(r) && r.id != null && r.id!.isNotEmpty)
                    _deletingRatingId == r.id
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 32,
                            ),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.textLight,
                            ),
                            tooltip: 'Delete this entry',
                            onPressed: () => _confirmDeleteReview(r),
                          ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Rating',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              _buildReviewStarsRow(r),
              if (r.reviewText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Review',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                if (fullReviewText)
                  SelectableText(
                    r.reviewText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textDark,
                    ),
                  )
                else
                  _ExpandableReviewText(text: r.reviewText),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Rated ${r.rating} star${r.rating == 1 ? '' : 's'} (no written note)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStarsRow(MealReviewItem r) {
    final mine = _isMyReview(r) && r.id != null && r.id!.isNotEmpty;
    final busy = _deletingRatingId == r.id;

    if (!mine || busy) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final filled = i < r.rating;
          return Icon(
            filled ? Icons.star : Icons.star_border,
            size: 18,
            color: filled ? Colors.amber : AppColors.textLight,
          );
        }),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= r.rating;
        final icon = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            size: 18,
            color: filled ? Colors.amber : AppColors.textLight,
          ),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (star == r.rating) {
              _performDeleteReview(r);
            }
          },
          child: star == r.rating
              ? Tooltip(
                  message: 'Tap again to remove',
                  child: icon,
                )
              : icon,
        );
      }),
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

/// Long review text: show two lines by default with Read more / Show less.
class _ExpandableReviewText extends StatefulWidget {
  const _ExpandableReviewText({required this.text});

  final String text;

  @override
  State<_ExpandableReviewText> createState() => _ExpandableReviewTextState();
}

class _ExpandableReviewTextState extends State<_ExpandableReviewText> {
  bool _expanded = false;

  static const TextStyle _style = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: AppColors.textDark,
  );

  static const int _collapsedLines = 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: _style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final needsToggle = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_expanded)
              SelectableText(widget.text, style: _style)
            else
              Text(
                widget.text,
                style: _style,
                maxLines: _collapsedLines,
                overflow: TextOverflow.ellipsis,
              ),
            if (needsToggle)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
          ],
        );
      },
    );
  }
}
