import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Must be a top-level function for background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Initializes Firebase Cloud Messaging: permission, token, foreground handling.
/// Call after [Firebase.initializeApp] and after registering [firebaseMessagingBackgroundHandler].
Future<void> initFirebaseCloudMessaging() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    return;
  }

  // iOS: FCM `getToken()` requires APNS token first; it arrives shortly after permission.
  if (Platform.isIOS) {
    await _waitForApnsToken(messaging);
  }

  await _fetchFcmTokenWithRetries(messaging);
}

/// Poll until APNS token is set (required on iOS before [FirebaseMessaging.getToken]).
Future<void> _waitForApnsToken(FirebaseMessaging messaging) async {
  const attempts = 80;
  const delay = Duration(milliseconds: 250);
  for (var i = 0; i < attempts; i++) {
    final apns = await messaging.getAPNSToken();
    if (apns != null) {
      return;
    }
    await Future<void>.delayed(delay);
  }
}

/// Retries [FirebaseMessaging.getToken]; the token may still arrive later via
/// [FirebaseMessaging.onTokenRefresh] once APNs connects.
Future<void> _fetchFcmTokenWithRetries(FirebaseMessaging messaging) async {
  const maxAttempts = 12;
  const delay = Duration(milliseconds: 500);
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        return;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'apns-token-not-set') rethrow;
    }
    await Future<void>.delayed(delay);
  }
}
