import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local "decision list" — meal IDs the user shortlists from the feed.
class DecisionListService {
  static const _key = 'decision_meal_ids';

  static Future<Set<String>> getIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> toggle(String mealId) async {
    final set = await getIds();
    if (set.contains(mealId)) {
      set.remove(mealId);
    } else {
      set.add(mealId);
    }
    await _save(set);
  }

  static Future<void> add(String mealId) async {
    final set = await getIds();
    set.add(mealId);
    await _save(set);
  }

  static Future<void> remove(String mealId) async {
    final set = await getIds();
    set.remove(mealId);
    await _save(set);
  }

  static Future<void> _save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }
}
