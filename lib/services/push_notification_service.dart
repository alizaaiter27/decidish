import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Must be a top-level function for background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
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

  if (kDebugMode) {
    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    return;
  }

  // Listen first so we never miss an early token.
  messaging.onTokenRefresh.listen((String t) {
    if (kDebugMode) {
      debugPrint('FCM token (Firebase console → Send test message): $t');
    }
  });

  // iOS: FCM `getToken()` requires APNS token first; it arrives shortly after permission.
  if (Platform.isIOS) {
    await _waitForApnsToken(messaging);
  }

  await _logFcmTokenWithRetries(messaging);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        'FCM foreground: ${message.notification?.title} — ${message.notification?.body}',
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('FCM opened from notification: ${message.messageId}');
    }
  });
}

/// Poll until APNS token is set (required on iOS before [FirebaseMessaging.getToken]).
Future<void> _waitForApnsToken(FirebaseMessaging messaging) async {
  const attempts = 80;
  const delay = Duration(milliseconds: 250);
  for (var i = 0; i < attempts; i++) {
    final apns = await messaging.getAPNSToken();
    if (apns != null) {
      if (kDebugMode) {
        debugPrint('APNS token available; fetching FCM token…');
      }
      return;
    }
    await Future<void>.delayed(delay);
  }
  if (kDebugMode) {
    debugPrint(
      'APNS token still null after ~${attempts * delay.inMilliseconds ~/ 1000}s — '
      'Simulator cannot receive push; on a real device check Push capability & APNs key in Firebase.',
    );
  }
}

/// Retries [getToken] briefly; token may still arrive later via [onTokenRefresh].
Future<void> _logFcmTokenWithRetries(FirebaseMessaging messaging) async {
  const maxAttempts = 12;
  const delay = Duration(milliseconds: 500);
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          debugPrint('FCM token (Firebase console → Send test message): $token');
        }
        return;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'apns-token-not-set') rethrow;
    }
    await Future<void>.delayed(delay);
  }
  if (kDebugMode) {
    debugPrint(
      'FCM token not ready yet — when APNs connects, the token will print above from onTokenRefresh.',
    );
  }
}
