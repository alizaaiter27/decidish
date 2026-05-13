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
  String get foodLibrary => _isTurkish ? 'Yemek kütüphanesi' : 'Food library';
  String mealCount(int total) => total == 1
      ? (_isTurkish ? 'DeciDish\'te 1 yemek' : '1 meal in DeciDish')
      : (_isTurkish ? 'DeciDish\'te $total yemek' : '$total meals in DeciDish');
  String resultCount(int total) => total == 1
      ? (_isTurkish ? '1 sonuç' : '1 result')
      : (_isTurkish ? '$total sonuç' : '$total results');
  String get searchMealHint => _isTurkish ? 'Yemek ara…' : 'Search meals…';
  String get clear => _isTurkish ? 'Temizle' : 'Clear';
  String get retry => _isTurkish ? 'Tekrar dene' : 'Retry';
  String get mealLoadError => _isTurkish
      ? 'Yemekler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'
      : 'Could not load meals. Check your connection and try again.';
  String get searchDescription => _isTurkish
      ? 'İsim, mutfak, tür veya etiket ile ara.'
      : 'Search by name, cuisine, type, or tag.';
  String get sortedDescription => _isTurkish
      ? 'A-Z sıralı. Detayları açmak için bir yemeğe dokunun.'
      : 'Sorted A-Z. Tap a dish to open details.';
  String get emptyLibraryLong => _isTurkish
      ? 'Kütüphane henüz boş.\n\nTarifler MongoDB\'de tutulur: backend import scriptlerini '
            '(import:themealdb, import:spoonacular, import:open-cookbook) API ile aynı MONGODB_URI ile '
            'çalıştırın, sonra yenilemek için aşağı çekin.'
      : 'No meals in the library yet.\n\nRecipes live in MongoDB: run the backend import scripts '
            '(import:themealdb, import:spoonacular, import:open-cookbook) using the same MONGODB_URI '
            'as your API, then pull to refresh.';
  String get noMealsMatchSearch => _isTurkish
      ? 'Aramanızla eşleşen yemek yok.'
      : 'No meals match your search.';
  String get noMealsInLibrary =>
      _isTurkish ? 'Kütüphane henüz boş.' : 'No meals in the library yet.';

  String get preferences => _isTurkish ? 'Tercihler' : 'Preferences';
  String get dietType => _isTurkish ? 'Beslenme tipi' : 'Diet type';
  String get preferredCuisines =>
      _isTurkish ? 'Tercih edilen mutfaklar' : 'Preferred cuisines';
  String get preferredCuisineHelp => _isTurkish
      ? 'Burada yalnızca kütüphanenizdeki yemeklerde bulunan mutfaklar görünür. Tümünü dahil etmek için boş bırakın.'
      : 'Only cuisines that exist on meals in your library appear here. Leave empty to include all.';
  String get allergies => _isTurkish ? 'Alerjiler' : 'Allergies';
  String get allergyHelp => _isTurkish
      ? 'Arayıp seçmek için alana dokunun. Bunu önerileri yönlendirmek için kullanırız - şiddetli alerjiniz varsa malzemeleri her zaman doğrulayın.'
      : 'Tap the field to search and select. We use this to steer recommendations-always confirm ingredients if you have a severe allergy.';
  String get ingredientsToAvoid =>
      _isTurkish ? 'Kaçınılacak malzemeler' : 'Ingredients to avoid';
  String get ingredientsToAvoidHelp => _isTurkish
      ? 'Bu malzemeleri öne çıkaran tariflerden kaçınmaya çalışırız.'
      : 'We try to avoid recipes that highlight these ingredients.';
  String get savePreferences =>
      _isTurkish ? 'Tercihleri kaydet' : 'Save preferences';
  String get preferencesSaved => _isTurkish
      ? 'Tercihler başarıyla kaydedildi'
      : 'Preferences saved successfully';
  String errorLoadingPreferences(String message) => _isTurkish
      ? 'Tercihler yüklenirken hata: $message'
      : 'Error loading preferences: $message';
  String errorSavingPreferences(String message) => _isTurkish
      ? 'Tercihler kaydedilirken hata: $message'
      : 'Error saving preferences: $message';
  String get cuisineSearchHint => _isTurkish
      ? 'Kütüphanende mutfak ara…'
      : 'Search cuisines in your library…';
  String get noCuisinesMatch => _isTurkish
      ? 'Aramaya uygun mutfak yok.'
      : 'No cuisines match your search.';
  String get noCuisinesFound => _isTurkish
      ? 'Yemek kütüphanende henüz mutfak bulunmadı. Mutfak bilgisi olan yemekler ekleyip tekrar aç.'
      : 'No cuisines found in your meal library yet. Add meals with a cuisine set, then open preferences again.';
  String get allergySearchHint =>
      _isTurkish ? 'Alerji ara…' : 'Search allergies…';
  String get noAllergiesMatch => _isTurkish
      ? 'Aramaya uygun alerji yok.'
      : 'No allergies match your search.';
  String get noAllergyOptions =>
      _isTurkish ? 'Alerji seçeneği yok.' : 'No allergy options available.';
  String get clearAll => _isTurkish ? 'Tümünü temizle' : 'Clear all';
  String get language => _isTurkish ? 'Dil' : 'Language';
  String get systemDefault =>
      _isTurkish ? 'Sistem varsayılanı' : 'System default';
  String get english => _isTurkish ? 'İngilizce' : 'English';
  String get turkish => _isTurkish ? 'Türkçe' : 'Turkish';

  String get navHome => _isTurkish ? 'Ana sayfa' : 'Home';
  String get navFeed => _isTurkish ? 'Akış' : 'Feed';
  String get navFavorites => _isTurkish ? 'Favoriler' : 'Favorites';
  String get navChats => _isTurkish ? 'Sohbetler' : 'Chats';
  String get navProfile => _isTurkish ? 'Profil' : 'Profile';

  String greeting(String name) => _isTurkish ? 'Merhaba, $name' : 'Hi, $name';
  String get decideWhatToEat =>
      _isTurkish ? 'Ne yiyeceğine karar ver' : 'Decide what to eat';
  String get notifications => _isTurkish ? 'Bildirimler' : 'Notifications';
  String get yourRankedMatches =>
      _isTurkish ? 'Sıralı eşleşmelerin' : 'Your ranked matches';
  String get higherPointsBetterFit => _isTurkish
      ? 'Yüksek puan = şu an senin için daha iyi uyum.'
      : 'Higher points = better fit for you right now.';
  String get noMealsToRank => _isTurkish
      ? 'Henüz sıralanacak yemek yok. API\'nin çalıştığını ve yemeklerin yüklendiğini kontrol et.'
      : 'No meals to rank yet. Check that the API is running and meals are seeded.';
  String get pickForMe => _isTurkish ? 'Benim için seç' : 'Pick for me';
  String get pickForMeDescription => _isTurkish
      ? '5 hızlı soruyu yanıtla - ruh hali, bütçe, porsiyon, süre - sonra kısa bir yemek listesi al.'
      : 'Tap to answer 5 quick questions - mood, budget, portion, time - then get a short list of meal ideas.';
  String get decideForMe =>
      _isTurkish ? 'Benim için karar ver' : 'Decide for me';
  String get foodLibraryDescription => _isTurkish
      ? 'Uygulamadaki tüm yemeklere göz at - A\'dan Z\'ye canlı sayaçla.'
      : 'Browse every meal in the app - A to Z with a live count.';
  String get cookWithWhatIHave =>
      _isTurkish ? 'Elimdekilerle pişir' : 'Cook with what I have';
  String get pantryDescription => _isTurkish
      ? 'Malzemelerini listele - sende olanlara göre sıralanmış fikirler al.'
      : 'List your ingredients - get ideas ranked by what you already have.';
  String get howMatchPointsWork =>
      _isTurkish ? 'Eşleşme puanları nasıl çalışır' : 'How match points work';
  String get matchPointsDescription => _isTurkish
      ? 'Puanlar; beslenme ve damak tercihlerin, kaydettiğin yemeklere benzerlik ve diğerlerinin favorileme sıklığını birleştirir. Detayları görmek için bir yemeğe dokun.'
      : 'Points mix your diet & taste settings, similarity to foods you saved, and how often others favorite a dish. Tap a meal to see details.';
  String get bestMatch => _isTurkish ? 'EN İYİ EŞLEŞME' : 'BEST MATCH';
  String points(int score) => _isTurkish ? '$score puan' : '$score pts';

  String get getStarted => _isTurkish ? 'Başla' : 'Get Started';
  String get login => _isTurkish ? 'Giriş yap' : 'Login';
  String get signup => _isTurkish ? 'Kayıt ol' : 'Sign up';
  String get emailRequired =>
      _isTurkish ? 'E-posta zorunludur' : 'Email is required';
  String get enterValidEmail =>
      _isTurkish ? 'Geçerli bir e-posta girin' : 'Enter a valid email';
  String get passwordRequired =>
      _isTurkish ? 'Şifre zorunludur' : 'Password is required';
  String get passwordMinLength => _isTurkish
      ? 'Şifre en az 6 karakter olmalı'
      : 'Password must be at least 6 characters';
  String get loginFailed => _isTurkish ? 'Giriş başarısız' : 'Login failed';
  String get enterYourEmail =>
      _isTurkish ? 'E-postanizi girin' : 'Enter your email';
  String get enterYourPassword =>
      _isTurkish ? 'Şifrenizi girin' : 'Enter your password';
  String get forgotPassword =>
      _isTurkish ? 'Şifreni mi unuttun?' : 'Forgot Password?';
  String get dontHaveAccount =>
      _isTurkish ? 'Hesabın yok mu? ' : 'Don\'t have an account? ';
  String get signupLower => _isTurkish ? 'kayıt ol' : 'sign up';
  String get loginLower => _isTurkish ? 'giriş yap' : 'login';
  String get backToLogin => _isTurkish ? 'Girişe dön' : 'Back to login';
  String get nameRequired =>
      _isTurkish ? 'İsim zorunludur' : 'Name is required';
  String get nameTooShort => _isTurkish ? 'İsim çok kısa' : 'Name is too short';
  String get confirmPassword =>
      _isTurkish ? 'Şifrenizi doğrulayın' : 'Confirm your password';
  String get confirmPasswordRequired =>
      _isTurkish ? 'Şifrenizi doğrulayın' : 'Confirm your password';
  String get passwordsDoNotMatch =>
      _isTurkish ? 'Şifreler eşleşmiyor' : 'Passwords do not match';
  String get signupFailed => _isTurkish ? 'Kayıt başarısız' : 'Sign up failed';
  String get yourName => _isTurkish ? 'Adınız' : 'Your name';

  String stepOf(int step, int total) =>
      _isTurkish ? '$total içinden $step. adım' : 'Step $step of $total';
  String get back => _isTurkish ? 'Geri' : 'Back';
  String get skip => _isTurkish ? 'Atla' : 'Skip';
  String get next => _isTurkish ? 'İleri' : 'Next';
  String get onboardingWelcomeTitle =>
      _isTurkish ? 'DeciDish\'e hoş geldin!' : 'Welcome to DeciDish!';
  String get onboardingWelcomeDescription => _isTurkish
      ? 'Yemek deneyimini kişiselleştirelim. Tercihlerini anlamak için birkaç soru soracağız.'
      : 'Let\'s personalize your food experience. We\'ll ask a few questions to understand your preferences.';
  String get dietTypeQuestion =>
      _isTurkish ? 'Beslenme tipin nedir?' : 'What\'s your diet type?';
  String get chooseBestDiet => _isTurkish
      ? 'Seni en iyi tanımlayanı seç'
      : 'Choose one that best describes you';
  String get allergyQuestion =>
      _isTurkish ? 'Alerjin var mı?' : 'Any allergies?';
  String get selectAllOptional => _isTurkish
      ? 'Uygun olanları seç (isteğe bağlı)'
      : 'Select all that apply (optional)';
  String get foodPreferences =>
      _isTurkish ? 'Yemek tercihleri' : 'Food Preferences';
  String get likesDislikesQuestion => _isTurkish
      ? 'Neleri seviyor, neleri sevmiyorsun?'
      : 'What do you like and dislike?';

  String get profile => _isTurkish ? 'Profil' : 'Profile';
  String get loading => _isTurkish ? 'Yükleniyor...' : 'Loading...';
  String get friends => _isTurkish ? 'Arkadaşlar' : 'Friends';
  String get friendsSubtitle => _isTurkish
      ? 'Ara, kişi ekle ve istekleri gör'
      : 'Search, add people, and see requests';
  String get mealHistory => _isTurkish ? 'Yemek geçmişi' : 'Meal history';
  String get mealHistorySubtitle => _isTurkish
      ? 'Önerilerden denediğin yemekler'
      : 'Meals you tried from recommendations';
  String get editPreferences =>
      _isTurkish ? 'Tercihleri düzenle' : 'Edit Preferences';
  String get editPreferencesSubtitle => _isTurkish
      ? 'Beslenme, alerji ve yemek tercihlerini değiştir'
      : 'Change diet, allergies, and food preferences';
  String get changePassword =>
      _isTurkish ? 'Şifreyi değiştir' : 'Change password';
  String get changePasswordSubtitle =>
      _isTurkish ? 'Hesap şifreni güncelle' : 'Update your account password';
  String get notificationsSubtitle =>
      _isTurkish ? 'Bildirim ayarlarını yönet' : 'Manage notification settings';
  String get helpAndSupport =>
      _isTurkish ? 'Yardım ve destek' : 'Help & Support';
  String get helpAndSupportSubtitle => _isTurkish
      ? 'Yardım al veya destekle iletişime geç'
      : 'Get help or contact support';
  String get about => _isTurkish ? 'Hakkında' : 'About';
  String get comingSoonNotificationSettings => _isTurkish
      ? 'Bildirim ayarları yakında gelecek.'
      : 'Notification settings are coming soon.';
  String get ok => 'OK';
  String get supportEmailText => _isTurkish
      ? 'Destek için support@decidish.com adresine e-posta gönderin.'
      : 'For support, please email support@decidish.com.';
  String get close => _isTurkish ? 'Kapat' : 'Close';
  String get logout => _isTurkish ? 'Çıkış yap' : 'Logout';
  String get passwordUpdated =>
      _isTurkish ? 'Şifre güncellendi' : 'Password updated';
  String logoutError(String msg) =>
      _isTurkish ? 'Çıkış hatası: $msg' : 'Logout error: $msg';
  String dietLabel(String diet) =>
      _isTurkish ? 'Beslenme: $diet' : 'Diet: $diet';
  String get somethingWentWrong =>
      _isTurkish ? 'Bir şeyler ters gitti.' : 'Something went wrong.';
  String get currentPassword =>
      _isTurkish ? 'Mevcut şifre' : 'Current password';
  String get newPasswordMin6 => _isTurkish
      ? 'Yeni şifre (en az 6 karakter)'
      : 'New password (min 6 characters)';
  String get confirmNewPassword =>
      _isTurkish ? 'Yeni şifreyi doğrula' : 'Confirm new password';
  String get required => _isTurkish ? 'Zorunlu' : 'Required';
  String get atLeast6Chars =>
      _isTurkish ? 'En az 6 karakter' : 'At least 6 characters';
  String get doesNotMatch => _isTurkish ? 'Eşleşmiyor' : 'Does not match';
  String get cancel => _isTurkish ? 'İptal' : 'Cancel';
  String get save => _isTurkish ? 'Kaydet' : 'Save';

  String get favorites => _isTurkish ? 'Favoriler' : 'Favorites';
  String get removedFromFavorites =>
      _isTurkish ? 'Favorilerden kaldırıldı' : 'Removed from favorites';
  String genericError(String msg) => _isTurkish ? 'Hata: $msg' : 'Error: $msg';
  String get noFavoritesYet =>
      _isTurkish ? 'Henüz favori yok' : 'No favorites yet';

  String get pushNotifications =>
      _isTurkish ? 'Anlık bildirimler' : 'Push notifications';
  String get pushNotificationsBody => _isTurkish
      ? 'DeciDish, izin verdiğinde yemek önerileri, arkadaş etkinliği ve hatırlatmalar için push bildirimleri kullanır.'
      : 'DeciDish uses push for meal ideas, friend activity, and reminders when you allow them in iOS Settings -> DeciDish -> Notifications.';
  String get notificationsMorePrefs => _isTurkish
      ? 'Daha fazla bildirim tercihi (sessiz saatler, kategoriler) buraya sonra eklenebilir.'
      : 'More notification preferences (quiet hours, categories) can be added here later.';

  String get pantryTitle =>
      _isTurkish ? 'Elimdekilerle pişir' : 'Cook with what I have';
  String get pantryIntro => _isTurkish
      ? 'Buzdolabı veya erzak dolabındakileri listele. Yapabileceğin veya neredeyse yapabileceğin yemekleri önerelim.'
      : 'List what\'s in your fridge or pantry. We\'ll suggest dishes you can make or almost make.';
  String get pantryHint =>
      _isTurkish ? 'ör. tavuk, pirinç, limon' : 'e.g. chicken, rice, lime';
  String get add => _isTurkish ? 'Ekle' : 'Add';
  String get searching => _isTurkish ? 'Aranıyor…' : 'Searching…';
  String get findMealIdeas =>
      _isTurkish ? 'Yemek fikirleri bul' : 'Find meal ideas';
  String get addAtLeastOneIngredient => _isTurkish
      ? 'En az bir malzeme ekleyin.'
      : 'Add at least one ingredient.';
  String get noPantryMatches => _isTurkish
      ? 'Bu malzemelerle henüz tarif bulunamadı. Sık kullandığın temel malzemeleri dene (pirinç, yumurta, makarna, soğan...).'
      : 'No recipes matched those items yet. Try staples you often cook with (rice, eggs, pasta, onion...).';
  String get tryAgainGeneric => _isTurkish
      ? 'Bir şeyler ters gitti. Tekrar dene.'
      : 'Something went wrong. Try again.';
  String stillNeed(String items) =>
      _isTurkish ? 'Hâlâ gerekli: $items' : 'Still need: $items';

  String get all => _isTurkish ? 'Tümü' : 'All';
  String get meals => _isTurkish ? 'Yemekler' : 'Meals';
  String get social => _isTurkish ? 'Sosyal' : 'Social';
  String get community => _isTurkish ? 'Topluluk' : 'Community';
  String get feedTagline =>
      _isTurkish ? 'Karar ver.Ye.Keyfini çıkar' : 'Decide.Eat.Enjoy';
  String streakLabel(int count) => _isTurkish ? '$count seri' : '$count streak';
  String get newPost => _isTurkish ? 'Yeni gönderi' : 'New post';
  String get couldNotSaveRating =>
      _isTurkish ? 'Puan kaydedilemedi' : 'Could not save rating';
  String get couldNotRemoveRating =>
      _isTurkish ? 'Puan kaldırılamadı' : 'Could not remove rating';
  String get couldNotSaveReview =>
      _isTurkish ? 'Yorum kaydedilemedi' : 'Could not save review';
  String get couldNotLoadMeal =>
      _isTurkish ? 'Yemek yüklenemedi' : 'Could not load meal';
  String get couldNotUpdateLike =>
      _isTurkish ? 'Beğeni güncellenemedi' : 'Could not update like';
  String get couldNotGetRecommendation =>
      _isTurkish ? 'Öneri alınamadı' : 'Could not get recommendation';
  String get postedToCommunity =>
      _isTurkish ? 'Topluluğa gönderildi' : 'Posted to the community';
  String get quickDecide => _isTurkish ? 'Hızlı karar' : 'Quick decide';
  String get quickDecideSubtitle => _isTurkish
      ? 'Birini seç ya da uygulamanın senin için seçmesine izin ver'
      : 'Pick one or let the app choose for you';
  String get pick => _isTurkish ? 'Seç' : 'Pick';
  String get shuffleOptions =>
      _isTurkish ? 'Seçenekleri karıştır' : 'Shuffle options';
  String get surpriseMe => _isTurkish ? 'Sürpriz yap' : 'Surprise me';
  String get writtenReview => _isTurkish ? 'Yazılı yorum' : 'Written review';
  String get decisionList => _isTurkish ? 'Karar listesi' : 'Decision list';
  String get someone => _isTurkish ? 'Birisi' : 'Someone';
  String get recipe => _isTurkish ? 'Tarif' : 'Recipe';
  String get meal => _isTurkish ? 'Yemek' : 'Meal';
  String likesCount(int count) => _isTurkish ? '$count beğeni' : '$count likes';
  String get shareWithCommunity =>
      _isTurkish ? 'Toplulukla paylaş' : 'Share with the community';
  String get postInputHint => _isTurkish
      ? 'Kısa yorum, ipucu veya sevdiğin yemek…'
      : 'Quick review, tip, or dish you loved…';
  String get attachMealOptional =>
      _isTurkish ? 'Yemek ekle (isteğe bağlı)' : 'Attach a meal (optional)';
  String get changeAttachedMeal =>
      _isTurkish ? 'Ekli yemeği değiştir' : 'Change attached meal';
  String get remove => _isTurkish ? 'Kaldır' : 'Remove';
  String get post => _isTurkish ? 'Gönder' : 'Post';
  String get searchMealsToAttach =>
      _isTurkish ? 'Eklenecek yemek ara' : 'Search meals to attach';

  String get friendRequests =>
      _isTurkish ? 'Arkadaş istekleri' : 'Friend Requests';
  String get friendRequestsTooltip =>
      _isTurkish ? 'Arkadaş istekleri' : 'Friend requests';
  String get searchByNameOrEmail =>
      _isTurkish ? 'İsim veya e-posta ile ara' : 'Search by name or email';
  String get typeAtLeast2CharsHelp => _isTurkish
      ? 'En az 2 karakter yazın. Zaten arkadaş olanlar gizlenir.'
      : 'Type at least 2 characters. People already in your list are hidden.';
  String personWantsToConnect(int count) => _isTurkish
      ? (count == 1
            ? '1 kişi bağlantı kurmak istiyor'
            : '$count kişi bağlantı kurmak istiyor')
      : (count == 1
            ? '1 person wants to connect'
            : '$count people want to connect');
  String get noNewPeopleMatch => _isTurkish
      ? 'Bu aramaya uyan yeni kişi yok.'
      : 'No new people match that search.';
  String get noNewPeopleMatchFriends => _isTurkish
      ? 'Yeni kişi bulunamadı (listelenenlerin hepsi zaten arkadaşın olabilir).'
      : 'No new people match (everyone listed may already be your friend).';
  String get yourFriends => _isTurkish ? 'Arkadaşların' : 'Your friends';
  String get noFriendsYet =>
      _isTurkish ? 'Henüz arkadaş yok' : 'No friends yet';
  String get searchAndAddFriendsHelp => _isTurkish
      ? 'İsim veya e-posta ile kişileri arayıp Ekle\'ye dokun.'
      : 'Search above to find people by name or email and tap Add.';
  String get noFriendsAddFromSearch => _isTurkish
      ? 'Henüz arkadaş yok - yukarıdaki arama sonuçlarından birini ekle.'
      : 'No friends yet — add someone from the search results above.';
  String get couldNotReadUserId =>
      _isTurkish ? 'Kullanıcı kimliği okunamadı' : 'Could not read user id';
  String get friendRequestSent =>
      _isTurkish ? 'Arkadaş isteği gönderildi' : 'Friend request sent';
  String get removeFriend => _isTurkish ? 'Arkadaşı kaldır' : 'Remove friend';
  String removeFriendPrompt(String name) => _isTurkish
      ? '$name adlı kişiyi arkadaşlarından kaldırmak istiyor musun?'
      : 'Remove $name from your friends?';
  String get friendRemoved =>
      _isTurkish ? 'Arkadaş kaldırıldı' : 'Friend removed';
  String unknownUserName() => _isTurkish ? 'Bilinmeyen' : 'Unknown';
  String get posts => _isTurkish ? 'Gönderiler' : 'Posts';
  String get message => _isTurkish ? 'Mesaj' : 'Message';

  String get noIncomingRequests =>
      _isTurkish ? 'Gelen istek yok' : 'No incoming requests';
  String get friendRequestAccepted =>
      _isTurkish ? 'Arkadaş isteği kabul edildi' : 'Friend request accepted';
  String get friendRequestDeclined =>
      _isTurkish ? 'Arkadaş isteği reddedildi' : 'Friend request declined';

  String get addFriend => _isTurkish ? 'Arkadaş ekle' : 'Add Friend';
  String get searchNameOrEmailMin2 => _isTurkish
      ? 'İsim veya e-posta ile ara (en az 2 karakter)'
      : 'Search by name or email (min. 2 characters)';
  String get resultsUpdateAsType => _isTurkish
      ? 'Sonuçlar yazdıkça güncellenir.'
      : 'Results update as you type.';

  String get noConversationsYet =>
      _isTurkish ? 'Henüz konuşma yok' : 'No conversations yet';
  String get addFriendsToStartChat => _isTurkish
      ? 'Arkadaşlar ekranından kişi ekleyin, ardından buradan sohbet başlatın.'
      : 'Add friends from the Friends screen, then open a chat from here.';
  String get findFriends => _isTurkish ? 'Arkadaş bul' : 'Find friends';
  String get member => _isTurkish ? 'Üye' : 'Member';
  String get chat => _isTurkish ? 'Sohbet' : 'Chat';
  String errorLoadingMessages(String message) => _isTurkish
      ? 'Mesajlar yüklenirken hata: $message'
      : 'Error loading messages: $message';
  String errorSendingMessage(String message) => _isTurkish
      ? 'Mesaj gönderilirken hata: $message'
      : 'Error sending message: $message';
  String get typeAMessage => _isTurkish ? 'Bir mesaj yazın' : 'Type a message';
  String get missingFriend =>
      _isTurkish ? 'Arkadaş bilgisi eksik' : 'Missing friend';
  String get noPostsYet => _isTurkish ? 'Henüz gönderi yok' : 'No posts yet';
  String get history => _isTurkish ? 'Geçmiş' : 'History';
  String get clearHistory => _isTurkish ? 'Geçmişi temizle' : 'Clear History';
  String get clearHistoryTooltip =>
      _isTurkish ? 'Geçmişi temizle' : 'Clear history';
  String get clearHistoryConfirm => _isTurkish
      ? 'Tüm yemek geçmişini temizlemek istediğine emin misin? Bu işlem geri alınamaz.'
      : 'Are you sure you want to clear all your meal history? This action cannot be undone.';
  String get historyCleared => _isTurkish
      ? 'Geçmiş başarıyla temizlendi'
      : 'History cleared successfully';
  String get clearHistoryFailed =>
      _isTurkish ? 'Geçmiş temizlenemedi' : 'Failed to clear history';
  String minutesAgo(int m) => _isTurkish ? '$m dakika önce' : '$m minutes ago';
  String hoursAgo(int h) => _isTurkish ? '$h saat önce' : '$h hours ago';
  String get yesterday => _isTurkish ? 'Dün' : 'Yesterday';
  String daysAgo(int d) => _isTurkish ? '$d gün önce' : '$d days ago';
  String get noMealHistoryYet =>
      _isTurkish ? 'Henüz yemek geçmişi yok' : 'No meal history yet';
  String get unknownDate => _isTurkish ? 'Tarih bilinmiyor' : 'Unknown date';
  String get unknownMeal => _isTurkish ? 'Bilinmeyen yemek' : 'Unknown meal';
  String get recommendation => _isTurkish ? 'Öneri' : 'Recommendation';
  String get noMealDataAvailable =>
      _isTurkish ? 'Yemek verisi yok' : 'No meal data available';
  String get tryRequestNewRecommendation => _isTurkish
      ? 'Geri dönüp yeni bir öneri istemeyi deneyin.'
      : 'Try going back and requesting a new recommendation.';
  String get yourMeal => _isTurkish ? 'Yemeğiniz' : 'Your Meal';
  String get basedOnYourPreferences =>
      _isTurkish ? 'Tercihlerinize göre' : 'Based on your preferences';
  String get savedToMealHistory =>
      _isTurkish ? 'Yemek geçmişine kaydedildi' : 'Saved to meal history';
  String get iTriedThisMeal =>
      _isTurkish ? 'Bu yemeği denedim' : 'I tried this meal';
  String get nutritionInformation =>
      _isTurkish ? 'Besin Değerleri' : 'Nutrition Information';
  String get calories => _isTurkish ? 'Kalori' : 'Calories';
  String get protein => _isTurkish ? 'Protein' : 'Protein';
  String get carbs => _isTurkish ? 'Karbonhidrat' : 'Carbs';
  String get fat => _isTurkish ? 'Yağ' : 'Fat';
  String get grams => _isTurkish ? 'gram' : 'grams';
  String get ingredients => _isTurkish ? 'Malzemeler' : 'Ingredients';
  String get recipeTitle => _isTurkish ? 'Tarif' : 'Recipe';
  String get noWrittenSteps => _isTurkish
      ? 'Bu yemek için henüz yazılı adımlar yok. Varsa aşağıdaki orijinal tarif bağlantısını açın.'
      : 'No written steps for this dish yet. Open the original recipe link below if available.';
  String get originalRecipe =>
      _isTurkish ? 'Orijinal tarif' : 'Original recipe';
  String get watchVideo => _isTurkish ? 'Videoyu izle' : 'Watch video';
  String get saving => _isTurkish ? 'Kaydediliyor…' : 'Saving…';
  String get addReview => _isTurkish ? 'Yorum ekle' : 'Add review';
  String get communityReviews =>
      _isTurkish ? 'Topluluk yorumları' : 'Community reviews';
  String get refreshReviews =>
      _isTurkish ? 'Yorumları yenile' : 'Refresh reviews';
  String get ratingsAndNotesFromMembers => _isTurkish
      ? 'Diğer üyelerin puanları ve notları'
      : 'Ratings and notes from other members';
  String get noReviewsYetHelp => _isTurkish
      ? 'Henüz yorum yok. Yukarıdan yorum ekleyebilir veya Akış üzerinden zamanla birden fazla yorum bırakabilirsiniz.'
      : 'No reviews yet. Use Add review above or the Feed — you can add more than one review over time.';
  String viewMoreReviews(int count) => _isTurkish
      ? 'Daha fazla yorum görüntüle ($count)'
      : 'View more reviews ($count)';
  String get updating => _isTurkish ? 'Güncelleniyor...' : 'Updating...';
  String get favorited => _isTurkish ? 'Favorilendi' : 'Favorited';
  String get favorite => _isTurkish ? 'Favori' : 'Favorite';
  String get tryAgain => _isTurkish ? 'Tekrar dene' : 'Try Again';
  String get reviewSaved => _isTurkish ? 'Yorum kaydedildi' : 'Review saved';
  String get reviewDeleted => _isTurkish ? 'Yorum silindi' : 'Review deleted';
  String get couldNotDeleteReview =>
      _isTurkish ? 'Yorum silinemedi' : 'Could not delete review';
  String get invalidLink => _isTurkish ? 'Geçersiz bağlantı' : 'Invalid link';
  String get cannotOpenLinkOnDevice => _isTurkish
      ? 'Bu bağlantı bu cihazda açılamıyor'
      : 'Cannot open this link on this device';
  String get couldNotOpenLink =>
      _isTurkish ? 'Bağlantı açılamadı' : 'Could not open link';
  String get addedToFavorites =>
      _isTurkish ? 'Favorilere eklendi' : 'Added to favorites';
  String get savedToHistory => _isTurkish
      ? 'Yemek geçmişinize kaydedildi'
      : 'Saved to your meal history';
  String get couldNotSaveToHistory =>
      _isTurkish ? 'Geçmişe kaydedilemedi' : 'Could not save to history';
  String get deleteReviewQuestion =>
      _isTurkish ? 'Yorum silinsin mi?' : 'Delete review?';
  String get deleteReviewHelp => _isTurkish
      ? 'Bu giriş için verdiğiniz puanı ve yazılı yorumu kaldırır.'
      : 'This removes your rating and written review for this entry.';
  String get delete => _isTurkish ? 'Sil' : 'Delete';
  String allReviewsFor(String mealName) =>
      _isTurkish ? 'Tüm yorumlar · $mealName' : 'All reviews · $mealName';
  String get deleteThisEntry =>
      _isTurkish ? 'Bu girişi sil' : 'Delete this entry';
  String get rating => _isTurkish ? 'Puan' : 'Rating';
  String get review => _isTurkish ? 'Yorum' : 'Review';
  String ratedNoNote(int rating) => _isTurkish
      ? '$rating yıldız verildi (yazılı not yok)'
      : 'Rated $rating star${rating == 1 ? '' : 's'} (no written note)';
  String get tapAgainToRemove =>
      _isTurkish ? 'Kaldırmak için tekrar dokun' : 'Tap again to remove';
  String get showLess => _isTurkish ? 'Daha az göster' : 'Show less';
  String get readMore => _isTurkish ? 'Devamını oku' : 'Read more';
  String localizeFeedText(String text) {
    if (!_isTurkish) return text;
    final key = text.trim().toLowerCase();
    switch (key) {
      case 'for you':
        return 'Senin için';
      case 'because you liked':
        return 'Beğendiklerine göre';
      case 'community':
        return 'Topluluk';
      case 'friends':
        return 'Arkadaşlar';
      case 'trending':
        return 'Popüler';
      case 'quick picks':
        return 'Hızlı seçimler';
      default:
        return text;
    }
  }

  String get enhancedPreferences =>
      _isTurkish ? 'Gelişmiş tercihler' : 'Enhanced Preferences';
  String get preferredMealTypes =>
      _isTurkish ? 'Tercih edilen öğün türleri' : 'Preferred Meal Types';
  String get tastePreferences =>
      _isTurkish ? 'Tat tercihleri' : 'Taste Preferences';
  String get preferredCookingMethods => _isTurkish
      ? 'Tercih edilen pişirme yöntemleri'
      : 'Preferred Cooking Methods';
  String get dietaryRestrictions =>
      _isTurkish ? 'Beslenme kısıtlamaları' : 'Dietary Restrictions';
  String get timeAndDifficulty =>
      _isTurkish ? 'Süre ve zorluk' : 'Time & Difficulty';
  String get seasonalPreference =>
      _isTurkish ? 'Mevsim tercihi' : 'Seasonal Preference';
  String maxPreparationTime(int minutes) => _isTurkish
      ? 'Maksimum hazırlık süresi: $minutes dakika'
      : 'Max Preparation Time: $minutes minutes';
  String get helpMeDecide =>
      _isTurkish ? 'Karar vermeme yardım et' : 'Help me decide';
  String get questionMoodTitle =>
      _isTurkish ? 'Şu an canın ne çekiyor?' : 'What sounds good right now?';
  String get questionMoodSubtitle => _isTurkish ? 'Ruh hali' : 'Mood';
  String get moodComfort =>
      _isTurkish ? 'Rahatlatıcı ve sıcak' : 'Comfort & cozy';
  String get moodEnergetic =>
      _isTurkish ? 'Taze ve enerji verici' : 'Fresh & energizing';
  String get moodLight => _isTurkish ? 'Hafif ve kolay' : 'Light & easy';
  String get moodTreat => _isTurkish ? 'Biraz şımartıcı' : 'A little indulgent';
  String get questionMealTypeTitle =>
      _isTurkish ? 'Ne tür bir öğün?' : 'What kind of meal?';
  String get questionMealTypeSubtitle => _isTurkish ? 'Öğün' : 'Occasion';
  String get questionBudgetTitle =>
      _isTurkish ? 'Yaklaşık bütçe (market)' : 'Rough budget (groceries)';
  String get questionBudgetSubtitle =>
      _isTurkish ? 'Porsiyon başı, yaklaşık' : 'Per serving, approximate';
  String get budgetLow =>
      _isTurkish ? r'$ — bütçe dostu' : r'$ — budget-friendly';
  String get budgetMedium =>
      _isTurkish ? r'$$ — orta seviye' : r'$$ — moderate';
  String get budgetHigh => _isTurkish ? r'$$$ — esnek' : r'$$$ — flexible';
  String get questionPortionTitle =>
      _isTurkish ? 'Porsiyon boyutu' : 'Portion size';
  String get questionPortionSubtitle =>
      _isTurkish ? 'Ne kadar açsın?' : 'How hungry are you?';
  String get portionLight => _isTurkish ? 'Hafif' : 'Light';
  String get portionRegular => _isTurkish ? 'Normal' : 'Regular';
  String get portionHearty => _isTurkish ? 'Doyurucu' : 'Hearty';
  String get questionTimeTitle =>
      _isTurkish ? 'Pişirme süresi' : 'Time to cook';
  String get questionTimeSubtitle =>
      _isTurkish ? 'Hazırlık ve pişirme' : 'Prep & cook';
  String get timeQuick =>
      _isTurkish ? 'Hızlı (~25 dk veya daha az)' : 'Quick (~25 min or less)';
  String get timeMedium => _isTurkish ? 'Orta (~45 dk)' : 'Medium (~45 min)';
  String get timeFlexible => _isTurkish ? 'Acil değil' : 'No rush';
  String get breakfast => _isTurkish ? 'Kahvaltı' : 'Breakfast';
  String get lunch => _isTurkish ? 'Öğle yemeği' : 'Lunch';
  String get dinner => _isTurkish ? 'Akşam yemeği' : 'Dinner';
  String get snack => _isTurkish ? 'Atıştırmalık' : 'Snack';
  String get dessert => _isTurkish ? 'Tatlı' : 'Dessert';
  String get seeIdeas => _isTurkish ? 'Fikirleri gör' : 'See ideas';
  String get noMatchesYetTryDifferent => _isTurkish
      ? 'Henüz eşleşme yok — farklı cevaplar deneyin.'
      : 'No matches yet — try different answers.';
  String get ideasForYou =>
      _isTurkish ? 'Senin için fikirler' : 'Ideas for you';
  String get ideasHelpText => _isTurkish
      ? 'Tam önizleme için bir yemeğe dokun — Geri seni buraya döndürür. Bitirdiğinde bu paneli kapat.'
      : 'Tap a meal for a full preview — Back returns you here. Close this sheet when you are done.';
  String matchPoints(int points) =>
      _isTurkish ? 'Eşleşme $points puan' : 'Match $points pts';
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
