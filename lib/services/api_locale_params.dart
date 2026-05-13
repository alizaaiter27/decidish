import 'dart:ui' as ui;

import '../l10n/locale_controller.dart';

/// Appends `lang=tr` when the effective UI language is Turkish so meal APIs
/// return merged `localeTr` fields from the server.
class ApiLocaleParams {
  ApiLocaleParams._();

  /// True when the user expects Turkish meal text (saved `tr`, system default
  /// with Turkish in the platform locale list, or Material resolved locale).
  static bool get wantsTurkishMealContent {
    final manual = LocaleController.localeNotifier.value?.languageCode;
    if (manual == 'tr') return true;
    if (manual != null) return false;

    for (final l in ui.PlatformDispatcher.instance.locales) {
      if (l.languageCode == 'tr') return true;
    }
    return false;
  }

  /// Sent on every HTTP request so meal routes still resolve Turkish if a URL
  /// omits `?lang=tr`. Omitted when not Turkish to avoid overriding server defaults.
  static String? get acceptLanguageForMeals =>
      wantsTurkishMealContent ? 'tr' : null;

  /// Use on GET/POST paths that return localized meal payloads (`?lang=tr` or `&lang=tr`).
  static String withMealContentLang(String path) {
    if (!wantsTurkishMealContent) return path;
    final sep = path.contains('?') ? '&' : '?';
    return '$path${sep}lang=tr';
  }
}
