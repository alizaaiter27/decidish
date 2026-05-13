import 'package:decidish/models/meal_model.dart';
import 'package:decidish/l10n/app_strings.dart';
import 'package:decidish/services/meal_api_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/widgets/meal_network_image.dart';
import 'package:flutter/material.dart';

/// Full catalog of meals in the app, sorted A–Z by name.
class MealLibraryScreen extends StatefulWidget {
  const MealLibraryScreen({super.key});

  @override
  State<MealLibraryScreen> createState() => _MealLibraryScreenState();
}

class _MealLibraryScreenState extends State<MealLibraryScreen> {
  List<MealModel> _allMeals = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await MealApiService.getMeals();
      if (!mounted) return;
      final sorted = List<MealModel>.from(raw)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _allMeals = sorted;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppStrings.of(context).mealLoadError;
      });
    }
  }

  List<MealModel> _visibleMeals() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _allMeals;
    return _allMeals.where((m) {
      if (m.name.toLowerCase().contains(q)) return true;
      final c = m.cuisine?.toLowerCase() ?? '';
      if (c.contains(q)) return true;
      final mt = m.mealType?.toLowerCase() ?? '';
      if (mt.contains(q)) return true;
      if (m.tags != null) {
        for (final t in m.tags!) {
          if (t.toLowerCase().contains(q)) return true;
        }
      }
      return false;
    }).toList();
  }

  void _openMeal(MealModel meal) {
    Navigator.pushNamed(context, '/recommendation', arguments: meal);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final total = _allMeals.length;
    final visible = _visibleMeals();
    final searching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(strings.foodLibrary),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.mealCount(total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (searching) ...[
                    const SizedBox(height: 4),
                    Text(
                      strings.resultCount(visible.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    searching
                        ? strings.searchDescription
                        : strings.sortedDescription,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: strings.searchMealHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: strings.clear,
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.secondary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.8),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              child: Text(strings.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _allMeals.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return RefreshIndicator(
                          onRefresh: _load,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    strings.emptyLibraryLong,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          searching
                              ? strings.noMealsMatchSearch
                              : strings.noMealsInLibrary,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final meal = visible[i];
                          final sub = [
                            if (meal.cuisine != null &&
                                meal.cuisine!.trim().isNotEmpty)
                              meal.cuisine,
                            if (meal.mealType != null &&
                                meal.mealType!.trim().isNotEmpty)
                              meal.mealType,
                          ].join(' · ');
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openMeal(meal),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: MealNetworkImage(
                                        imageUrl: meal.imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(10),
                                        iconSize: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          if (sub.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              sub,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textLight.withValues(
                                        alpha: 0.7,
                                      ),
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
