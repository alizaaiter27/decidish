import 'package:decidish/models/meal_model.dart';
import 'package:decidish/services/api_service.dart' show ApiException;
import 'package:decidish/services/meal_api_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/widgets/meal_network_image.dart';
import 'package:flutter/material.dart';

/// Enter ingredients you have at home; see meals ranked by how well they match.
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final List<String> _ingredients = [];
  List<MealModel> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    if (_ingredients.contains(t)) {
      _input.clear();
      return;
    }
    setState(() {
      _ingredients.add(t);
      _input.clear();
      _error = null;
    });
  }

  void _removeIngredient(String s) {
    setState(() {
      _ingredients.remove(s);
      _results = [];
    });
  }

  Future<void> _search() async {
    if (_ingredients.isEmpty) {
      setState(() => _error = 'Add at least one ingredient.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meals = await MealApiService.getMealsFromPantry(_ingredients);
      if (!mounted) return;
      setState(() {
        _results = meals;
        _loading = false;
        if (meals.isEmpty) {
          _error =
              'No recipes matched those items yet. Try staples you often cook with (rice, eggs, pasta, onion…).';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException
            ? e.message
            : 'Something went wrong. Try again.';
      });
    }
  }

  void _openMeal(MealModel meal) {
    Navigator.pushNamed(context, '/recommendation', arguments: meal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: const Text('Cook with what I have'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'List what’s in your fridge or pantry. We’ll suggest dishes you can make or almost make.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textLight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addIngredient(),
                      decoration: InputDecoration(
                        hintText: 'e.g. chicken, rice, lime',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.secondary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.secondary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FilledButton(
                      onPressed: _addIngredient,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
            if (_ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ingredients
                      .map(
                        (s) => InputChip(
                          label: Text(s),
                          onDeleted: () => _removeIngredient(s),
                          deleteIconColor: AppColors.textLight,
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.6,
                          ),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(_loading ? 'Searching…' : 'Find meal ideas'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_error != null && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _results.isEmpty && _ingredients.isNotEmpty
                        ? AppColors.textLight
                        : AppColors.error,
                  ),
                ),
              ),
            Expanded(
              child: _results.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final meal = _results[i];
                        final pm = meal.pantryMatch;
                        return Material(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _openMeal(meal),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: MealNetworkImage(
                                        imageUrl: meal.imageUrl,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(10),
                                        iconSize: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                meal.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                            ),
                                            if (pm != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20),
                                                ),
                                                child: Text(
                                                  '${pm.coveragePercent}%',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (meal.cuisine != null &&
                                            meal.cuisine!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            meal.cuisine!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textLight,
                                            ),
                                          ),
                                        ],
                                        if (pm != null &&
                                            pm.missingIngredients
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Still need: ${pm.missingIngredients.join(', ')}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              height: 1.35,
                                              color: AppColors.textLight,
                                            ),
                                          ),
                                        ],
                                      ],
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
          ],
        ),
      ),
    );
  }
}
