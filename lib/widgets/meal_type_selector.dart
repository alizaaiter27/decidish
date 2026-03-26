import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class MealTypeSelector extends StatefulWidget {
  final String? selectedMealType;
  final Function(String) onMealTypeSelected;

  const MealTypeSelector({
    super.key,
    this.selectedMealType,
    required this.onMealTypeSelected,
  });

  @override
  State<MealTypeSelector> createState() => _MealTypeSelectorState();
}

class _MealTypeSelectorState extends State<MealTypeSelector> {
  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];

  String? _selectedType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedMealType;
  }

  @override
  Widget build(BuildContext context) {
    final filteredMealTypes = _mealTypes
        .where(
          (type) => type.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    // Calculate available height more precisely
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final availableHeight =
        screenHeight - viewInsets.bottom - 100; // Reserve space for system UI

    return Container(
      constraints: BoxConstraints(maxHeight: availableHeight),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'What type of meal are you looking for?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search meal types...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          // Meal type grid with flexible height
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 120, // Minimum height for the grid
                maxHeight:
                    availableHeight *
                    0.6, // Increased maximum height for better spacing
              ),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      2.8, // Reduced ratio for more vertical space
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredMealTypes.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final mealType = filteredMealTypes[index];
                  final isSelected = _selectedType == mealType;
                  final icon = _getMealTypeIcon(mealType);
                  final color = _getMealTypeColor(mealType);

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedType = mealType);
                      widget.onMealTypeSelected(mealType);
                      // Don't pop here - let the callback handle navigation
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: isSelected ? color : Colors.grey[600],
                            size: 18,
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              mealType,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected ? color : AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              _getMealTypeDescription(mealType),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelected ? color : Colors.grey[500],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Auto-detect button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final now = DateTime.now();
                final hour = now.hour;
                String autoMealType = 'Lunch'; // default

                if (hour >= 5 && hour < 11) {
                  autoMealType = 'Breakfast';
                } else if (hour >= 11 && hour < 15) {
                  autoMealType = 'Lunch';
                } else if (hour >= 15 && hour < 21) {
                  autoMealType = 'Dinner';
                } else {
                  autoMealType = 'Snack';
                }

                widget.onMealTypeSelected(autoMealType);
                // Don't pop here - let the callback handle navigation
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Auto-detect based on time'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.wb_sunny;
      case 'Lunch':
        return Icons.wb_cloudy;
      case 'Dinner':
        return Icons.nights_stay;
      case 'Snack':
        return Icons.cookie;
      case 'Dessert':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Colors.orange;
      case 'Lunch':
        return Colors.blue;
      case 'Dinner':
        return Colors.purple;
      case 'Snack':
        return Colors.green;
      case 'Dessert':
        return Colors.pink;
      default:
        return AppColors.primary;
    }
  }

  String _getMealTypeDescription(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return 'Start your day right';
      case 'Lunch':
        return 'Midday energy boost';
      case 'Dinner':
        return 'Evening satisfaction';
      case 'Snack':
        return 'Quick bite';
      case 'Dessert':
        return 'Sweet treat';
      default:
        return '';
    }
  }
}
