import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/services/user_api_service.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // User preferences
  String? _dietType;
  final List<String> _allergies = [];
  final List<String> _likes = [];
  final List<String> _dislikes = [];

  final List<String> _dietTypes = [
    'Regular',
    'Vegetarian',
    'Vegan',
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

  final List<String> _foodOptions = [
    'Chicken',
    'Beef',
    'Fish',
    'Pasta',
    'Rice',
    'Salad',
    'Pizza',
    'Burger',
    'Sushi',
    'Tacos',
  ];

  int get _totalSteps => 4;

  void _nextPage() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _savePreferencesAndContinue();
    }
  }

  void _prevPage() {
    if (_isSaving) return;
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      // If you want: allow going back to signup/login
      Navigator.pop(context);
    }
  }

  Future<void> _savePreferencesAndContinue() async {
    setState(() => _isSaving = true);

    try {
      // Map "Regular" to "Omnivore" for backend compatibility
      String? dietType = _dietType;
      if (dietType == 'Regular') {
        dietType = 'Omnivore';
      }

      // Build preferences object
      final preferences = <String, dynamic>{
        'allergies': _allergies,
        'dislikedIngredients': _dislikes,
        'preferredCuisines': _likes,
      };

      // Save to backend
      await UserApiService.completeOnboarding(
        dietType: dietType,
        preferences: preferences,
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
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

  @override
  Widget build(BuildContext context) {
    final stepText = 'Step ${_currentPage + 1} of $_totalSteps';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Progress Header (Back + Step text + Animated progress bar)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _prevPage,
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.textDark,
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stepText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      // Optional: skip (only show before last step)
                      if (_currentPage < _totalSteps - 1)
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  // jump to last step
                                  _pageController.animateToPage(
                                    _totalSteps - 1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          child: const Text(
                            'Skip',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar track + fill
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final progress =
                            (_currentPage + 1) / _totalSteps; // 0..1
                        final fillWidth = constraints.maxWidth * progress;

                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: fillWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                // ✅ Optional: disable swipe so user uses Next (more controlled)
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildDietTypePage(),
                  _buildAllergiesPage(),
                  _buildPreferencesPage(),
                ],
              ),
            ),

            // Next Button (unchanged except label logic kept)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _nextPage,
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
                      : Text(
                          _currentPage == _totalSteps - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waving_hand, size: 80, color: AppColors.primary),
          const SizedBox(height: 30),
          const Text(
            'Welcome to DeciDish!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Let\'s personalize your food experience. We\'ll ask a few questions to understand your preferences.',
            style: TextStyle(fontSize: 16, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDietTypePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your diet type?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Choose one that best describes you',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _dietTypes.length,
              itemBuilder: (context, index) {
                final diet = _dietTypes[index];
                final isSelected = _dietType == diet;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() => _dietType = diet);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            diet,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textDark,
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
    );
  }

  Widget _buildAllergiesPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Any allergies?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select all that apply (optional)',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _allergyOptions.length,
              itemBuilder: (context, index) {
                final allergy = _allergyOptions[index];
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
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        allergy,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Food Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'What do you like and dislike?',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _foodOptions.length,
              itemBuilder: (context, index) {
                final food = _foodOptions[index];
                final isLiked = _likes.contains(food);
                final isDisliked = _dislikes.contains(food);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            food,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (isLiked) {
                                _likes.remove(food);
                              } else {
                                _likes.add(food);
                                _dislikes.remove(food);
                              }
                            });
                          },
                          icon: Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: isLiked
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (isDisliked) {
                                _dislikes.remove(food);
                              } else {
                                _dislikes.add(food);
                                _likes.remove(food);
                              }
                            });
                          },
                          icon: Icon(
                            isDisliked
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            color: isDisliked
                                ? AppColors.error
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
