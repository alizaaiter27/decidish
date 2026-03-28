import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:decidish/services/push_notification_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/pantry_screen.dart';
import 'screens/meal_library_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/add_friend_screen.dart';
import 'screens/friend_posts_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/history_screen.dart';
import 'utils/app_colors.dart';
import 'utils/page_transitions.dart';

//hello world =
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const DeciDishApp());
  // After first frame so iOS can finish registerForRemoteNotifications + APNs handshake.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initFirebaseCloudMessaging();
  });
}

class DeciDishApp extends StatelessWidget {
  const DeciDishApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      // You can also control brightness if needed:
      // brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'DeciDish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const WelcomeScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return FadePageRoute(
              page: const LoginScreen(),
              settings: settings,
            );
          case '/login':
            return SlidePageRoute(
              page: const LoginScreen(),
              settings: settings,
            );
          case '/signup':
            return SlidePageRoute(
              page: const SignUpScreen(),
              settings: settings,
            );
          case '/onboarding':
            return SlidePageRoute(
              page: const OnboardingScreen(),
              settings: settings,
            );
          case '/home':
            return FadePageRoute(
              page: const MainNavigationScreen(),
              settings: settings,
            );
          case '/recommendation':
            return SlidePageRoute(
              page: const RecommendationScreen(),
              settings: settings,
            );
          case '/friends':
            return SlidePageRoute(
              page: const FriendsScreen(),
              settings: settings,
            );
          case '/friend_requests':
            return SlidePageRoute(
              page: const FriendRequestsScreen(),
              settings: settings,
            );
          case '/chat':
            return SlidePageRoute(page: const ChatScreen(), settings: settings);
          case '/add_friend':
            return SlidePageRoute(
              page: const AddFriendScreen(),
              settings: settings,
            );
          case '/friend_posts':
            return SlidePageRoute(
              page: const FriendPostsScreen(),
              settings: settings,
            );
          case '/preferences':
            return SlidePageRoute(
              page: const PreferencesScreen(),
              settings: settings,
            );
          case '/pantry':
            return SlidePageRoute(
              page: const PantryScreen(),
              settings: settings,
            );
          case '/meal_library':
            return SlidePageRoute(
              page: const MealLibraryScreen(),
              settings: settings,
            );
          case '/notifications':
            return SlidePageRoute(
              page: const NotificationsScreen(),
              settings: settings,
            );
          case '/history':
            return SlidePageRoute(
              page: const HistoryScreen(),
              settings: settings,
            );
          default:
            return FadePageRoute(
              page: const LoginScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}
