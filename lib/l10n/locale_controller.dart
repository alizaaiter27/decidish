import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  LocaleController._();

  static const _localeKey = 'app_locale';
  static final ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(
    null,
  );

  static Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == null || code.isEmpty) return;
    localeNotifier.value = Locale(code);
  }

  static Future<void> setLocale(Locale? locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
      return;
    }
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
