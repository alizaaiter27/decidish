import 'package:flutter/material.dart';

class AppStrings {
  AppStrings._(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static const supportedLocales = <Locale>[Locale('en'), Locale('tr')];

  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    assert(strings != null, 'No AppStrings found in context');
    return strings!;
  }

  bool get _isTurkish => locale.languageCode == 'tr';

  String get appTitle => _isTurkish ? 'DeciDish' : 'DeciDish';
  String get foodLibrary => _isTurkish ? 'Yemek kutuphanesi' : 'Food library';
  String mealCount(int total) => total == 1
      ? (_isTurkish ? 'DeciDish\'te 1 yemek' : '1 meal in DeciDish')
      : (_isTurkish ? 'DeciDish\'te $total yemek' : '$total meals in DeciDish');
  String resultCount(int total) => total == 1
      ? (_isTurkish ? '1 sonuc' : '1 result')
      : (_isTurkish ? '$total sonuc' : '$total results');
  String get searchMealHint => _isTurkish ? 'Yemek ara…' : 'Search meals…';
  String get clear => _isTurkish ? 'Temizle' : 'Clear';
  String get retry => _isTurkish ? 'Tekrar dene' : 'Retry';
  String get mealLoadError => _isTurkish
      ? 'Yemekler yuklenemedi. Baglantinizi kontrol edip tekrar deneyin.'
      : 'Could not load meals. Check your connection and try again.';
  String get searchDescription => _isTurkish
      ? 'Isim, mutfak, tur veya etiket ile ara.'
      : 'Search by name, cuisine, type, or tag.';
  String get sortedDescription => _isTurkish
      ? 'A-Z sirali. Detaylari acmak icin bir yemeye dokunun.'
      : 'Sorted A-Z. Tap a dish to open details.';
  String get emptyLibraryLong => _isTurkish
      ? 'Kutuphane henuz bos.\n\nTarifler MongoDB\'de tutulur: backend import scriptlerini '
            '(import:themealdb, import:spoonacular, import:open-cookbook) API ile ayni MONGODB_URI ile '
            'calistirin, sonra yenilemek icin asagi cekin.'
      : 'No meals in the library yet.\n\nRecipes live in MongoDB: run the backend import scripts '
            '(import:themealdb, import:spoonacular, import:open-cookbook) using the same MONGODB_URI '
            'as your API, then pull to refresh.';
  String get noMealsMatchSearch => _isTurkish
      ? 'Aramanizla eslesen yemek yok.'
      : 'No meals match your search.';
  String get noMealsInLibrary =>
      _isTurkish ? 'Kutuphane henuz bos.' : 'No meals in the library yet.';

  String get preferences => _isTurkish ? 'Tercihler' : 'Preferences';
  String get dietType => _isTurkish ? 'Beslenme tipi' : 'Diet type';
  String get preferredCuisines =>
      _isTurkish ? 'Tercih edilen mutfaklar' : 'Preferred cuisines';
  String get preferredCuisineHelp => _isTurkish
      ? 'Burada yalnizca kutuphanenizdeki yemeklerde bulunan mutfaklar gorunur. Tumunu dahil etmek icin bos birakin.'
      : 'Only cuisines that exist on meals in your library appear here. Leave empty to include all.';
  String get allergies => _isTurkish ? 'Alerjiler' : 'Allergies';
  String get allergyHelp => _isTurkish
      ? 'Arayip secmek icin alana dokunun. Bunu onerileri yonlendirmek icin kullaniriz - siddetli alerjiniz varsa malzemeleri her zaman dogrulayin.'
      : 'Tap the field to search and select. We use this to steer recommendations-always confirm ingredients if you have a severe allergy.';
  String get ingredientsToAvoid =>
      _isTurkish ? 'Kacinilacak malzemeler' : 'Ingredients to avoid';
  String get ingredientsToAvoidHelp => _isTurkish
      ? 'Bu malzemeleri one cikaran tariflerden kacinmaya calisiriz.'
      : 'We try to avoid recipes that highlight these ingredients.';
  String get savePreferences =>
      _isTurkish ? 'Tercihleri kaydet' : 'Save preferences';
  String get preferencesSaved => _isTurkish
      ? 'Tercihler basariyla kaydedildi'
      : 'Preferences saved successfully';
  String errorLoadingPreferences(String message) => _isTurkish
      ? 'Tercihler yuklenirken hata: $message'
      : 'Error loading preferences: $message';
  String errorSavingPreferences(String message) => _isTurkish
      ? 'Tercihler kaydedilirken hata: $message'
      : 'Error saving preferences: $message';
  String get cuisineSearchHint => _isTurkish
      ? 'Kutuphanende mutfak ara…'
      : 'Search cuisines in your library…';
  String get noCuisinesMatch => _isTurkish
      ? 'Aramaya uygun mutfak yok.'
      : 'No cuisines match your search.';
  String get noCuisinesFound => _isTurkish
      ? 'Yemek kutuphanende henuz mutfak bulunmadi. Mutfak bilgisi olan yemekler ekleyip tekrar ac.'
      : 'No cuisines found in your meal library yet. Add meals with a cuisine set, then open preferences again.';
  String get allergySearchHint =>
      _isTurkish ? 'Alerji ara…' : 'Search allergies…';
  String get noAllergiesMatch => _isTurkish
      ? 'Aramaya uygun alerji yok.'
      : 'No allergies match your search.';
  String get noAllergyOptions =>
      _isTurkish ? 'Alerji secenegi yok.' : 'No allergy options available.';
  String get clearAll => _isTurkish ? 'Tumunu temizle' : 'Clear all';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings._(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
