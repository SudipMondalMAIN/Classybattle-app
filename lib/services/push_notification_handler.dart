import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler required by FirebaseMessaging.onBackgroundMessage --
/// must not be a class member (isolate entry point requirement).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// Wires up foreground FCM messages to a local notification so they're
/// visible while the app is open, and logs the device token needed for
/// backend registration (POST /notifications/device-tokens, per
/// FIREBASE_SETUP.md) once an auth flow exists to send it.
class PushNotificationHandler {
  PushNotificationHandler._();
  static final PushNotificationHandler instance = PushNotificationHandler._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'classybattle_default',
            'ClassyBattle Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM device token: $token');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }
}
