import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/user_api_service.dart';
import '../models/user_model.dart';

class EnhancedPreferencesScreen extends StatefulWidget {
  const EnhancedPreferencesScreen({super.key});

  @override
  State<EnhancedPreferencesScreen> createState() =>
      _EnhancedPreferencesScreenState();
}

class _EnhancedPreferencesScreenState extends State<EnhancedPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  UserModel? _currentUser;

  // Meal type preferences
  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];
  List<String> _selectedMealTypes = [];

  // Taste preferences
  double _sweetLevel = 2.0;
  double _saltyLevel = 2.0;
  double _spicyLevel = 2.0;
  double _sourLevel = 1.0;
  double _bitterLevel = 0.0;
  double _umamiLevel = 2.0;

  // Cooking methods
  final List<String> _cookingMethods = [
    'Grilled',
    'Baked',
    'Fried',
    'Boiled',
    'Steamed',
    'Roasted',
    'Raw',
    'Stir-fried',
    'Slow-cooked',
  ];
  List<String> _selectedCookingMethods = [];

  // Dietary restrictions
  final List<String> _dietaryRestrictions = [
    'Low-carb',
    'Low-fat',
    'High-protein',
    'Low-sodium',
    'Sugar-free',
    'Dairy-free',
    'Nut-free',
  ];
  List<String> _selectedDietaryRestrictions = [];

  // Time and difficulty
  double _maxPrepTime = 60.0;
  String _selectedDifficulty = 'Medium';

  // Seasonal preference
  final List<String> _seasons = [
    'Spring',
    'Summer',
    'Fall',
    'Winter',
    'Year-round',
  ];
  String _selectedSeason = 'Year-round';

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  Future<void> _loadCurrentPreferences() async {
    try {
      final userData = await UserApiService.getProfile();
      setState(() {
        _currentUser = userData;

        if (_currentUser?.preferences != null) {
          final prefs = _currentUser!.preferences!;

          _selectedMealTypes = List<String>.from(
            prefs['preferredMealTypes'] ?? ['Lunch', 'Dinner'],
          );

          _selectedCookingMethods = List<String>.from(
            prefs['cookingMethods'] ?? ['Grilled', 'Baked'],
          );

          _selectedDietaryRestrictions = List<String>.from(
            prefs['dietaryRestrictions'] ?? [],
          );

          final tasteProfile = prefs['tasteProfile'] ?? {};
          _sweetLevel = (tasteProfile['sweet'] ?? 2).toDouble();
          _saltyLevel = (tasteProfile['salty'] ?? 2).toDouble();
          _spicyLevel = (tasteProfile['spicy'] ?? 2).toDouble();
          _sourLevel = (tasteProfile['sour'] ?? 1).toDouble();
          _bitterLevel = (tasteProfile['bitter'] ?? 0).toDouble();
          _umamiLevel = (tasteProfile['umami'] ?? 2).toDouble();

          _maxPrepTime = (prefs['maxPreparationTime'] ?? 60).toDouble();
          _selectedDifficulty = prefs['preferredDifficulty'] ?? 'Medium';
          _selectedSeason = prefs['seasonalPreference'] ?? 'Year-round';
        } else {
          _selectedMealTypes = ['Lunch', 'Dinner'];
          _selectedCookingMethods = ['Grilled', 'Baked'];
        }
      });
    } catch (_) {
      setState(() {
        _selectedMealTypes = ['Lunch', 'Dinner'];
        _selectedCookingMethods = ['Grilled', 'Baked'];
      });
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final preferences = {
        'tasteProfile': {
          'sweet': _sweetLevel.round(),
          'salty': _saltyLevel.round(),
          'spicy': _spicyLevel.round(),
          'sour': _sourLevel.round(),
          'bitter': _bitterLevel.round(),
          'umami': _umamiLevel.round(),
        },
        'preferredMealTypes': _selectedMealTypes,
        'cookingMethods': _selectedCookingMethods,
        'dietaryRestrictions': _selectedDietaryRestrictions,
        'maxPreparationTime': _maxPrepTime.round(),
        'preferredDifficulty': _selectedDifficulty,
        'seasonalPreference': _selectedSeason,
      };

      final updatedUser = await UserApiService.updateProfile(
        preferences: preferences,
      );

      setState(() => _currentUser = updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Enhanced Preferences',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Preferred Meal Types'),
              _buildMealTypeChips(),
              const SizedBox(height: 24),

              _buildSectionTitle('Taste Preferences'),
              _buildTastePreferences(),
              const SizedBox(height: 24),

              _buildSectionTitle('Preferred Cooking Methods'),
              _buildCookingMethodChips(),
              const SizedBox(height: 24),

              _buildSectionTitle('Dietary Restrictions'),
              _buildDietaryRestrictionChips(),
              const SizedBox(height: 24),

              _buildSectionTitle('Time & Difficulty'),
              _buildTimeAndDifficulty(),
              const SizedBox(height: 24),

              _buildSectionTitle('Seasonal Preference'),
              _buildSeasonalPreference(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildMealTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _mealTypes.map((mealType) {
        final isSelected = _selectedMealTypes.contains(mealType);
        return FilterChip(
          label: Text(mealType),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selected
                  ? _selectedMealTypes.add(mealType)
                  : _selectedMealTypes.remove(mealType);
            });
          },
          backgroundColor: Colors.grey[200],
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTastePreferences() {
    return Column(
      children: [
        _buildTasteSlider(
          'Sweet',
          Icons.cake,
          _sweetLevel,
          (v) => setState(() => _sweetLevel = v),
          Colors.pink,
        ),
        _buildTasteSlider(
          'Salty',
          Icons.grain,
          _saltyLevel,
          (v) => setState(() => _saltyLevel = v),
          Colors.blue,
        ),
        _buildTasteSlider(
          'Spicy',
          Icons.whatshot,
          _spicyLevel,
          (v) => setState(() => _spicyLevel = v),
          Colors.red,
        ),
        _buildTasteSlider(
          'Sour',
          Icons.emoji_food_beverage,
          _sourLevel,
          (v) => setState(() => _sourLevel = v),
          Colors.yellow,
        ),
        _buildTasteSlider(
          'Bitter',
          Icons.coffee,
          _bitterLevel,
          (v) => setState(() => _bitterLevel = v),
          Colors.brown,
        ),
        _buildTasteSlider(
          'Umami',
          Icons.ramen_dining,
          _umamiLevel,
          (v) => setState(() => _umamiLevel = v),
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTasteSlider(
    String label,
    IconData icon,
    double value,
    Function(double) onChanged,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text('$label: ${value.round()}'),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.3),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookingMethodChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cookingMethods.map((method) {
        final isSelected = _selectedCookingMethods.contains(method);
        return FilterChip(
          label: Text(method),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selected
                  ? _selectedCookingMethods.add(method)
                  : _selectedCookingMethods.remove(method);
            });
          },
          backgroundColor: Colors.grey[200],
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDietaryRestrictionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dietaryRestrictions.map((restriction) {
        final isSelected = _selectedDietaryRestrictions.contains(restriction);
        return FilterChip(
          label: Text(restriction),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selected
                  ? _selectedDietaryRestrictions.add(restriction)
                  : _selectedDietaryRestrictions.remove(restriction);
            });
          },
          backgroundColor: Colors.grey[200],
          selectedColor: AppColors.accent.withValues(alpha: 0.2),
          checkmarkColor: AppColors.accent,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeAndDifficulty() {
    return Column(
      children: [
        Text('Max Preparation Time: ${_maxPrepTime.round()} minutes'),
        Slider(
          value: _maxPrepTime,
          min: 15,
          max: 180,
          divisions: 11,
          onChanged: (v) => setState(() => _maxPrepTime = v),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildSeasonalPreference() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSeason,
      items: _seasons
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => _selectedSeason = v!),
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }
}
