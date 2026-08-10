import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

/// Must be a top-level function (not a class method) — this is required
/// by firebase_messaging for background message handling on Android.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate when the app is terminated/backgrounded.
  // Keep this minimal — no Riverpod/UI access here.
}

/// Wires Firebase Cloud Messaging: requests permission, fetches the FCM
/// token, registers it with the ClassyBattle backend
/// (`POST /notifications/device-tokens`), and shows a local heads-up
/// notification for foreground pushes (FCM does this automatically only
/// when the app is backgrounded/terminated).
class PushNotificationHandler {
  PushNotificationHandler._();
  static final PushNotificationHandler instance = PushNotificationHandler._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _notificationService = NotificationService();

  static const _androidChannel = AndroidNotificationChannel(
    'classybattle_default',
    'ClassyBattle Notifications',
    description: 'Tournament, wallet aar match update',
    importance: Importance.high,
  );

  /// Callback invoked when the user taps a notification (foreground local
  /// notification, or one that opened the app from background/terminated).
  /// Pass a route handler here from the app root so taps can deep-link
  /// (e.g. open a specific tournament).
  void Function(Map<String, dynamic> data)? onNotificationTap;

  Future<void> init() async {
    // Foreground notifications need an explicit local-notification channel
    // on Android — FCM only auto-displays them when backgrounded.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && onNotificationTap != null) {
          onNotificationTap!({'raw': response.payload});
        }
      },
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Push permission: ${settings.authorizationStatus}');

    await _registerToken();
    // Re-register if FCM rotates the token (reinstall, token refresh, etc).
    _messaging.onTokenRefresh.listen((_) => _registerToken());

    // App in foreground: FCM does NOT auto-show a notification, so show
    // one ourselves via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // User tapped a notification while app was backgrounded (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message.data);
    });

    // App was terminated and opened via a notification tap.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _notificationService.registerDeviceToken(token, platform: 'android');
        debugPrint('FCM token registered with backend');
      }
    } catch (e) {
      // Non-fatal — happens e.g. if user isn't logged in yet, or offline.
      debugPrint('FCM token registration skipped: $e');
    }
  }

  /// Call this right after a successful login/signup, in case the token
  /// was fetched before the user was authenticated (registration needs a
  /// bearer token — see ApiClient's interceptor).
  Future<void> registerTokenAfterLogin() => _registerToken();

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Call on logout so the backend stops sending push to this device
  /// under the old user's account.
  Future<void> deregisterCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _notificationService.deregisterDeviceToken(token);
      }
    } catch (e) {
      debugPrint('FCM token deregistration skipped: $e');
    }
  }
}
