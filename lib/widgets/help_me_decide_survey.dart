import 'package:decidish/models/meal_model.dart';
import 'package:decidish/services/survey_api_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// 5-question survey + results (meals only, not restaurants). Lightweight modal content.
class HelpMeDecideSurvey extends StatefulWidget {
  const HelpMeDecideSurvey({super.key});

  @override
  State<HelpMeDecideSurvey> createState() => _HelpMeDecideSurveyState();
}

class _HelpMeDecideSurveyState extends State<HelpMeDecideSurvey> {
  final PageController _pageController = PageController();
  int _page = 0;
  static const int _questionCount = 5;

  String? _mood;
  String? _mealType;
  String? _budgetTier;
  String? _portion;
  String? _timeFeeling;

  List<MealModel> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_page) {
      case 0:
        return _mood != null;
      case 1:
        return _mealType != null;
      case 2:
        return _budgetTier != null;
      case 3:
        return _portion != null;
      case 4:
        return _timeFeeling != null;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    if (_mood == null ||
        _mealType == null ||
        _budgetTier == null ||
        _portion == null ||
        _timeFeeling == null) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meals = await SurveyApiService.submitSurvey(
        mood: _mood!,
        mealType: _mealType!,
        budgetTier: _budgetTier!,
        portion: _portion!,
        timeFeeling: _timeFeeling!,
      );
      if (!mounted) return;
      setState(() {
        _results = meals;
        _loading = false;
        _page = _questionCount;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Opens meal detail on the root stack so Back returns to this list (sheet stays open).
  Future<void> _onMealTap(MealModel meal) async {
    try {
      await SurveyApiService.recordPick(
        mealId: meal.id,
        mood: _mood!,
        mealType: _mealType!,
        budgetTier: _budgetTier!,
        portion: _portion!,
        timeFeeling: _timeFeeling!,
      );
    } catch (_) {}
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).pushNamed(
      '/recommendation',
      arguments: meal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Help me decide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (_page < _questionCount)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    _questionCount,
                    (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? AppColors.primary
                              : AppColors.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _page < _questionCount
                  ? PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _page = i),
                      children: [
                        _QuestionPage(
                          title: 'What sounds good right now?',
                          subtitle: 'Mood',
                          options: const [
                            _Opt('comfort', 'Comfort & cozy'),
                            _Opt('energetic', 'Fresh & energizing'),
                            _Opt('light', 'Light & easy'),
                            _Opt('treat', 'A little indulgent'),
                          ],
                          selected: _mood,
                          onSelect: (v) => setState(() => _mood = v),
                        ),
                        _QuestionPage(
                          title: 'What kind of meal?',
                          subtitle: 'Occasion',
                          options: const [
                            _Opt('Breakfast', 'Breakfast'),
                            _Opt('Lunch', 'Lunch'),
                            _Opt('Dinner', 'Dinner'),
                            _Opt('Snack', 'Snack'),
                            _Opt('Dessert', 'Dessert'),
                          ],
                          selected: _mealType,
                          onSelect: (v) => setState(() => _mealType = v),
                        ),
                        _QuestionPage(
                          title: 'Rough budget (groceries)',
                          subtitle: 'Per serving, approximate',
                          options: const [
                            _Opt('low', r'$ — budget-friendly'),
                            _Opt('medium', r'$$ — moderate'),
                            _Opt('high', r'$$$ — flexible'),
                          ],
                          selected: _budgetTier,
                          onSelect: (v) => setState(() => _budgetTier = v),
                        ),
                        _QuestionPage(
                          title: 'Portion size',
                          subtitle: 'How hungry are you?',
                          options: const [
                            _Opt('light', 'Light'),
                            _Opt('regular', 'Regular'),
                            _Opt('hearty', 'Hearty'),
                          ],
                          selected: _portion,
                          onSelect: (v) => setState(() => _portion = v),
                        ),
                        _QuestionPage(
                          title: 'Time to cook',
                          subtitle: 'Prep & cook',
                          options: const [
                            _Opt('quick', 'Quick (~25 min or less)'),
                            _Opt('medium', 'Medium (~45 min)'),
                            _Opt('flexible', 'No rush'),
                          ],
                          selected: _timeFeeling,
                          onSelect: (v) => setState(() => _timeFeeling = v),
                        ),
                      ],
                    )
                  : _ResultsPage(
                      meals: _results,
                      error: _error,
                      onMealTap: _onMealTap,
                    ),
            ),
            if (_page < _questionCount && !_loading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                        child: const Text('Back'),
                      )
                    else
                      const SizedBox(width: 72),
                    Expanded(
                      child: FilledButton(
                        onPressed: !_canNext
                            ? null
                            : () {
                                if (_page < _questionCount - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                } else {
                                  _submit();
                                }
                              },
                        child: Text(
                          _page < _questionCount - 1 ? 'Next' : 'See ideas',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Opt {
  const _Opt(this.id, this.label);
  final String id;
  final String label;
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final List<_Opt> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text(
          subtitle.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ...options.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected == o.id
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onSelect(o.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected == o.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected == o.id
                            ? AppColors.primary
                            : AppColors.textLight,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          o.label,
                          style: TextStyle(
                            fontWeight: selected == o.id
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsPage extends StatelessWidget {
  const _ResultsPage({
    required this.meals,
    required this.error,
    required this.onMealTap,
  });

  final List<MealModel> meals;
  final String? error;
  final void Function(MealModel) onMealTap;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (meals.isEmpty) {
      return const Center(
        child: Text('No matches yet — try different answers.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text(
          'Ideas for you',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a meal for a full preview — Back returns you here. '
          'Close this sheet when you are done.',
          style: TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
        const SizedBox(height: 12),
        ...meals.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onMealTap(m),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (m.cuisine != null)
                              Text(
                                m.cuisine!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            if (m.compatibilityScore != null)
                              Text(
                                'Match ${m.compatibilityScore!.toStringAsFixed(0)} pts',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Returns the meal the user chose (for opening details), or null if dismissed.
Future<MealModel?> showHelpMeDecideSurvey(BuildContext context) {
  return showModalBottomSheet<MealModel?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, __) => const HelpMeDecideSurvey(),
    ),
  );
}
