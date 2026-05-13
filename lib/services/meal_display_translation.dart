import 'dart:math' as math;

import 'package:translator/translator.dart';

import '../models/meal_model.dart';
import 'api_locale_params.dart';

/// When Turkish is selected and the server did not merge `localeTr` (`displayLocale != tr`),
/// translates copy via [translator]. Uses **deduplicated batch prefetch** so lists and feed
/// do not issue one HTTP call per row.
class MealDisplayTranslation {
  MealDisplayTranslation._();

  static final GoogleTranslator _translator = GoogleTranslator();
  static final Map<String, String> _cache = {};

  static bool get _skip => !ApiLocaleParams.wantsTurkishMealContent;

  static bool _serverHasTurkish(String? displayLocale) =>
      displayLocale == 'tr';

  /// After [prefetchTurkish], returns cached translation or the original string.
  static String translatedOrOriginal(String text) {
    final t = text.trim();
    if (t.isEmpty) return text;
    return _cache[t] ?? text;
  }

  static Future<String> _line(String text) async {
    final t = text.trim();
    if (t.isEmpty) return text;
    final hit = _cache[t];
    if (hit != null) return hit;
    try {
      final translated = await _translator.translate(t, to: 'tr');
      final out = translated.text;
      _cache[t] = out;
      return out;
    } catch (_) {
      return text;
    }
  }

  /// Fills [_cache] for every unique non-empty string (uncached only), with parallel chunks.
  static Future<void> prefetchTurkish(
    Iterable<String> texts, {
    int chunkSize = 24,
  }) async {
    if (_skip) return;
    final unique = texts
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .where((s) => !_cache.containsKey(s))
        .toList();
    for (var i = 0; i < unique.length; i += chunkSize) {
      final end = math.min(i + chunkSize, unique.length);
      final chunk = unique.sublist(i, end);
      await Future.wait(chunk.map((s) => _line(s)));
    }
  }

  static List<String> _chunkLongTextParts(String body) {
    if (body.trim().isEmpty) return const [];
    const maxChunk = 3500;
    final parts = <String>[];
    var i = 0;
    while (i < body.length) {
      var end = math.min(i + maxChunk, body.length);
      if (end < body.length) {
        final slice = body.substring(i, end);
        final nl = slice.lastIndexOf('\n');
        if (nl > 200) {
          end = i + nl + 1;
        }
      }
      parts.add(body.substring(i, end));
      i = end;
    }
    return parts;
  }

  static Future<void> _prefetchForFullTranslate(MealModel m) async {
    if (_skip || _serverHasTurkish(m.displayLocale)) return;
    final keys = <String>{m.name.trim()};
    if (m.description != null && m.description!.trim().isNotEmpty) {
      keys.addAll(_chunkLongTextParts(m.description!));
    }
    if (m.ingredients != null) {
      for (final s in m.ingredients!) {
        keys.add(s.trim());
      }
    }
    if (m.ingredientLines != null) {
      for (final s in m.ingredientLines!) {
        keys.add(s.trim());
      }
    }
    final pm = m.pantryMatch;
    if (pm != null) {
      for (final s in pm.missingIngredients) {
        keys.add(s.trim());
      }
      for (final s in pm.matchedIngredients) {
        keys.add(s.trim());
      }
    }
    await prefetchTurkish(keys);
  }

  static Future<void> prefetchForFullTranslateMany(List<MealModel> meals) async {
    if (_skip || meals.isEmpty) return;
    final keys = <String>{};
    for (final m in meals) {
      if (_serverHasTurkish(m.displayLocale)) continue;
      _collectFullKeys(m, keys);
    }
    await prefetchTurkish(keys);
  }

  static void _collectFullKeys(MealModel m, Set<String> keys) {
    keys.add(m.name.trim());
    if (m.description != null && m.description!.trim().isNotEmpty) {
      keys.addAll(_chunkLongTextParts(m.description!));
    }
    if (m.ingredients != null) {
      for (final s in m.ingredients!) {
        keys.add(s.trim());
      }
    }
    if (m.ingredientLines != null) {
      for (final s in m.ingredientLines!) {
        keys.add(s.trim());
      }
    }
    final pm = m.pantryMatch;
    if (pm != null) {
      for (final s in pm.missingIngredients) {
        keys.add(s.trim());
      }
      for (final s in pm.matchedIngredients) {
        keys.add(s.trim());
      }
    }
  }

  static List<String> _mapLines(List<String> list) =>
      list.map((s) => translatedOrOriginal(s)).toList();

  static MealModel applyFullFromCache(MealModel m) {
    if (_skip || _serverHasTurkish(m.displayLocale)) return m;
    final name = translatedOrOriginal(m.name);
    String? desc;
    if (m.description != null && m.description!.trim().isNotEmpty) {
      final parts = _chunkLongTextParts(m.description!);
      desc = parts.map(translatedOrOriginal).join('\n').trim();
    } else {
      desc = m.description;
    }
    final ing = m.ingredients != null && m.ingredients!.isNotEmpty
        ? _mapLines(m.ingredients!)
        : m.ingredients;
    final lines = m.ingredientLines != null && m.ingredientLines!.isNotEmpty
        ? _mapLines(m.ingredientLines!)
        : m.ingredientLines;
    PantryMatchInfo? pm = m.pantryMatch;
    if (pm != null) {
      pm = PantryMatchInfo(
        matchedCount: pm.matchedCount,
        totalIngredients: pm.totalIngredients,
        coverage: pm.coverage,
        missingIngredients: pm.missingIngredients.isNotEmpty
            ? _mapLines(pm.missingIngredients)
            : pm.missingIngredients,
        matchedIngredients: pm.matchedIngredients.isNotEmpty
            ? _mapLines(pm.matchedIngredients)
            : pm.matchedIngredients,
      );
    }
    return m.copyWith(
      name: name,
      description: desc,
      ingredients: ing,
      ingredientLines: lines,
      pantryMatch: pm,
    );
  }

  static Future<MealModel> localizeLite(MealModel m) async {
    if (_skip || _serverHasTurkish(m.displayLocale)) return m;
    await prefetchTurkish([m.name]);
    return m.copyWith(name: translatedOrOriginal(m.name));
  }

  static Future<List<MealModel>> localizeLiteList(List<MealModel> meals) async {
    if (_skip || meals.isEmpty) return meals;
    final names = <String>{};
    for (final m in meals) {
      if (_serverHasTurkish(m.displayLocale)) continue;
      final t = m.name.trim();
      if (t.isNotEmpty) names.add(t);
    }
    await prefetchTurkish(names);
    return meals
        .map((m) {
          if (_serverHasTurkish(m.displayLocale)) return m;
          final n = translatedOrOriginal(m.name);
          if (n == m.name) return m;
          return m.copyWith(name: n);
        })
        .toList();
  }

  static Future<MealModel> localizeFull(MealModel m) async {
    if (_skip || _serverHasTurkish(m.displayLocale)) return m;
    await _prefetchForFullTranslate(m);
    return applyFullFromCache(m);
  }

  static Future<List<MealModel>> localizeFullList(List<MealModel> meals) async {
    if (_skip || meals.isEmpty) return meals;
    await prefetchForFullTranslateMany(meals);
    return meals.map(applyFullFromCache).toList();
  }
}
