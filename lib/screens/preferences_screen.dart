import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/meal_api_service.dart';
import 'package:decidish/services/user_api_service.dart';
import 'package:flutter/material.dart';

const List<String> kDislikeIngredientChips = [
  'Cilantro',
  'Mushrooms',
  'Olives',
  'Anchovies',
  'Blue cheese',
  'Coconut',
  'Eggplant',
  'Lamb',
  'Pork',
  'Shellfish',
];

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String? _dietType;
  final List<String> _allergies = [];
  final List<String> _preferredCuisines = [];
  final List<String> _dislikedIngredients = [];
  List<String> _cuisineAreaOptions = [];
  String _cuisineSearch = '';
  bool _isLoading = true;
  bool _cuisineAreasLoading = true;
  bool _isSaving = false;

  final List<String> _dietTypes = [
    'None',
    'Vegetarian',
    'Vegan',
    'Omnivore',
    'Keto',
    'Paleo',
    'Gluten-Free',
  ];

  final List<String> _allergyOptions = [
    'Nuts',
    'Dairy',
    'Gluten',
    'Shellfish',
    'Eggs',
    'Soy',
    'Fish',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _cuisineAreasLoading = true;
    });

    try {
      final user = await UserApiService.getProfile();

      _dietType = user.dietType ?? 'None';
      _allergies.clear();
      _preferredCuisines.clear();
      _dislikedIngredients.clear();

      if (user.preferences != null) {
        final p = user.preferences!;
        if (p['allergies'] != null) {
          _allergies.addAll(List<String>.from(p['allergies']));
        }
        if (p['preferredCuisines'] != null) {
          _preferredCuisines.addAll(
            List<String>.from(p['preferredCuisines']),
          );
        }
        if (p['dislikedIngredients'] != null) {
          _dislikedIngredients.addAll(
            List<String>.from(p['dislikedIngredients']),
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      List<String> areas = [];
      try {
        areas = await MealApiService.getCuisineAreas();
      } catch (_) {
        areas = [];
      }

      if (mounted) {
        setState(() {
          _cuisineAreaOptions = areas;
          _cuisineAreasLoading = false;
          for (final c in _preferredCuisines) {
            if (!_cuisineAreaOptions.any(
              (x) => x.toLowerCase() == c.toLowerCase(),
            )) {
              _cuisineAreaOptions = [..._cuisineAreaOptions, c];
            }
          }
          _cuisineAreaOptions.sort(
            (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _cuisineAreasLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading preferences: ${e.toString().replaceAll('ApiException: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      final preferences = <String, dynamic>{
        'allergies': _allergies,
        'dislikedIngredients': _dislikedIngredients,
        'preferredCuisines': _preferredCuisines,
      };

      await UserApiService.updateProfile(
        dietType: _dietType,
        preferences: preferences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving preferences: ${e.toString().replaceAll('ApiException: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleCuisine(String c) {
    setState(() {
      if (_preferredCuisines.contains(c)) {
        _preferredCuisines.remove(c);
      } else {
        _preferredCuisines.add(c);
      }
    });
  }

  void _toggleDislike(String d) {
    setState(() {
      if (_dislikedIngredients.contains(d)) {
        _dislikedIngredients.remove(d);
      } else {
        _dislikedIngredients.add(d);
      }
    });
  }

  Future<void> _showAddCustomCuisineDialog() async {
    final controller = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add cuisine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use the exact word stored on meals (e.g. Lebanese). '
              'TheMealDB does not list every country—Syrian, Saudi Arabian, '
              'Egyptian, and Moroccan often cover Middle Eastern recipes.',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. Lebanese',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim();
              Navigator.pop(ctx, t.isEmpty ? null : t);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (added == null || added.isEmpty || !mounted) return;
    setState(() {
      if (!_preferredCuisines.any((x) => x.toLowerCase() == added.toLowerCase())) {
        _preferredCuisines.add(added);
      }
      if (!_cuisineAreaOptions.any((x) => x.toLowerCase() == added.toLowerCase())) {
        _cuisineAreaOptions = [..._cuisineAreaOptions, added];
        _cuisineAreaOptions.sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );
      }
    });
  }

  Iterable<String> get _filteredCuisineAreas {
    final q = _cuisineSearch.trim().toLowerCase();
    if (q.isEmpty) return _cuisineAreaOptions;
    return _cuisineAreaOptions.where(
      (a) => a.toLowerCase().contains(q),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Preferences'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diet type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _dietTypes.map((diet) {
                      final isSelected = _dietType == diet;
                      return InkWell(
                        onTap: () => setState(() => _dietType = diet),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            diet,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Preferred cuisines',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'List is loaded from TheMealDB (official areas) plus any cuisines '
                    'already in your app database. Leave empty to include all.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search cuisines…',
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: AppColors.textLight,
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => _cuisineSearch = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: _showAddCustomCuisineDialog,
                        child: const Text('Custom'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_cuisineAreasLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_cuisineAreaOptions.isEmpty)
                    Text(
                      'Could not load cuisine list. Use “Custom” to type a cuisine, '
                      'or check that the API is running.',
                      style: TextStyle(fontSize: 13, color: AppColors.textLight),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filteredCuisineAreas.map((c) {
                        final sel = _preferredCuisines.contains(c);
                        return FilterChip(
                          label: Text(c),
                          selected: sel,
                          onSelected: (_) => _toggleCuisine(c),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.25),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: sel ? AppColors.primary : AppColors.textDark,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                  if (_preferredCuisines.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setState(() => _preferredCuisines.clear()),
                      child: const Text('Clear cuisines'),
                    ),
                  const SizedBox(height: 28),

                  const Text(
                    'Allergies',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _allergyOptions.map((allergy) {
                      final isSelected = _allergies.contains(allergy);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _allergies.remove(allergy);
                            } else {
                              _allergies.add(allergy);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            allergy,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Ingredients to avoid',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We try to avoid recipes that highlight these ingredients.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kDislikeIngredientChips.map((d) {
                      final sel = _dislikedIngredients.contains(d);
                      return FilterChip(
                        label: Text(d),
                        selected: sel,
                        onSelected: (_) => _toggleDislike(d),
                        selectedColor: AppColors.error.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.error,
                        labelStyle: TextStyle(
                          color: sel ? AppColors.error : AppColors.textDark,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save preferences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
