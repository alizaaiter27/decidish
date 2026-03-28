import 'package:decidish/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// Bottom sheet to edit star rating and optional written review for a meal.
/// Returns `(stars, trimmedText)` on save, or `null` if dismissed.
class MealReviewSheet extends StatefulWidget {
  const MealReviewSheet({
    super.key,
    required this.mealName,
    required this.initialStars,
    required this.initialText,
  });

  final String mealName;
  final int initialStars;
  final String initialText;

  @override
  State<MealReviewSheet> createState() => _MealReviewSheetState();
}

class _MealReviewSheetState extends State<MealReviewSheet> {
  late final TextEditingController _controller;
  late int _stars;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _stars = widget.initialStars.clamp(1, 5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.mealName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stars',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final s = i + 1;
                final filled = s <= _stars;
                return IconButton(
                  onPressed: () => setState(() => _stars = s),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? Colors.amber : AppColors.textLight,
                  ),
                );
              }),
            ),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Written review (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final text = _controller.text.trim();
                Navigator.pop(context, (_stars, text));
              },
              child: const Text('Save review'),
            ),
          ],
        ),
      ),
    );
  }
}
