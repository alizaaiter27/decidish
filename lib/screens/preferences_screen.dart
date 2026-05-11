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
  final TextEditingController _cuisineSearchController = TextEditingController();
  final FocusNode _cuisineSearchFocus = FocusNode();
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

  void _onCuisineFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _cuisineSearchFocus.addListener(_onCuisineFocusChanged);
    _loadPreferences();
  }

  @override
  void dispose() {
    _cuisineSearchFocus.removeListener(_onCuisineFocusChanged);
    _cuisineSearchFocus.dispose();
    _cuisineSearchController.dispose();
    super.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cuisineSearchFocus.requestFocus();
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

  Iterable<String> get _filteredCuisineAreas {
    final q = _cuisineSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _cuisineAreaOptions;
    return _cuisineAreaOptions.where(
      (a) => a.toLowerCase().contains(q),
    );
  }

  Widget _buildCuisinePicker() {
    if (_cuisineAreasLoading) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.2),
          ),
        ),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_cuisineAreaOptions.isEmpty) {
      return Text(
        'No cuisines found in your meal library yet. Add meals with a '
        'cuisine set, then open preferences again.',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textLight,
          height: 1.45,
        ),
      );
    }

    final focused = _cuisineSearchFocus.hasFocus;
    final filtered = _filteredCuisineAreas.toList();
    final showSuggestions = focused;

    return TapRegion(
      onTapOutside: (_) {
        if (_cuisineSearchFocus.hasFocus) {
          _cuisineSearchFocus.unfocus();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focused
                    ? AppColors.accent.withValues(alpha: 0.9)
                    : AppColors.textLight.withValues(alpha: 0.22),
                width: focused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: focused ? 0.2 : 0.12,
                  ),
                  blurRadius: focused ? 20 : 8,
                  offset: Offset(0, focused ? 8 : 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    checkboxTheme: CheckboxThemeData(
                      checkColor: const WidgetStatePropertyAll(AppColors.white),
                      fillColor: WidgetStateProperty.resolveWith((s) {
                        if (s.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return null;
                      }),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(
                              Icons.restaurant_menu_rounded,
                              size: 22,
                              color: AppColors.accent,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _cuisineSearchController,
                              focusNode: _cuisineSearchFocus,
                              textInputAction: TextInputAction.search,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search cuisines in your library…',
                                hintStyle: TextStyle(
                                  color: AppColors.textLight.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.fromLTRB(
                                  10,
                                  14,
                                  14,
                                  14,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.hardEdge,
                        child: showSuggestions
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.textLight.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 232,
                                    child: filtered.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                              child: Text(
                                                'No cuisines match your search.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            primary: false,
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            itemCount: filtered.length,
                                            separatorBuilder: (_, __) =>
                                                Divider(
                                              height: 1,
                                              thickness: 1,
                                              indent: 12,
                                              endIndent: 12,
                                              color: AppColors.textLight
                                                  .withValues(alpha: 0.12),
                                            ),
                                            itemBuilder: (context, i) {
                                              final c = filtered[i];
                                              final sel =
                                                  _preferredCuisines.contains(c);
                                              return CheckboxListTile(
                                                value: sel,
                                                onChanged: (_) =>
                                                    _toggleCuisine(c),
                                                title: Text(
                                                  c,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: sel
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    color: sel
                                                        ? AppColors.primary
                                                        : AppColors.textDark,
                                                  ),
                                                ),
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                dense: true,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_preferredCuisines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _preferredCuisines.map((c) {
                return InputChip(
                  label: Text(c),
                  onDeleted: () =>
                      setState(() => _preferredCuisines.remove(c)),
                  deleteIcon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.65),
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.45),
                  ),
                  labelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() => _preferredCuisines.clear()),
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
                  const SizedBox(height: 6),
                  Text(
                    'Only cuisines that exist on meals in your library appear here. '
                    'Leave empty to include all.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCuisinePicker(),
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
