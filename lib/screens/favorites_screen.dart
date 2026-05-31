import 'package:decidish/utils/app_colors.dart' show AppColors;
import 'package:decidish/l10n/app_strings.dart';
import 'package:decidish/l10n/locale_controller.dart';
import 'package:decidish/services/favorites_api_service.dart';
import 'package:decidish/models/meal_model.dart';
import 'package:decidish/widgets/meal_network_image.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with WidgetsBindingObserver {
  List<MealModel> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocaleController.localeNotifier.addListener(_onMealLocaleChanged);
    _loadFavorites();
  }

  @override
  void dispose() {
    LocaleController.localeNotifier.removeListener(_onMealLocaleChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onMealLocaleChanged() {
    if (mounted) _loadFavorites();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (mounted) _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favorites = await FavoritesApiService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(String mealId) async {
    try {
      final success = await FavoritesApiService.removeFavoriteByMealId(mealId);
      if (success && mounted) {
        setState(() {
          _favorites.removeWhere((meal) => meal.id == mealId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).removedFromFavorites),
            backgroundColor: AppColors.success,
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(
                context,
              ).genericError(e.toString().replaceAll('ApiException: ', '')),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    strings.favorites,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              strings.somethingWentWrong,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadFavorites,
                              child: Text(strings.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _favorites.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              strings.noFavoritesYet,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final meal = _favorites[index];
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(meal.id),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 250 + (index.clamp(0, 8) * 40),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, t, child) => Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - t)),
                                child: child,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/recommendation',
                                  arguments: meal,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: MealNetworkImage(
                                        imageUrl: meal.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(12),
                                        iconSize: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (meal.cuisine != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              meal.cuisine!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.local_fire_department,
                                                size: 14,
                                                color: AppColors.accent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${meal.nutrition.calories} kcal',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () => _removeFavorite(meal.id),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
