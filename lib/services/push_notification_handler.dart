import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/notification_providers.dart';
import '../providers/home_providers.dart';
import '../providers/wallet_providers.dart';
import '../providers/tournament_providers.dart';

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
///
/// It also drives the app's "silent auto-refresh": whenever a push
/// arrives while the app is open, it re-fetches the notification list
/// and unread count in the background via [container] so any open
/// screen picks up the new data on its own -- no visible spinner, no
/// manual pull-to-refresh needed.
class PushNotificationHandler {
  PushNotificationHandler._();
  static final PushNotificationHandler instance = PushNotificationHandler._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Timer? _pollTimer;
  ProviderContainer? _container;

  static const _pollInterval = Duration(minutes: 2);

  void _startTimer(ProviderContainer container) {
    _container = container;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => _silentRefreshAll(container),
    );
  }

  /// Call when the app goes to the background (paused/inactive/hidden
  /// lifecycle states). Stops the background poll entirely — no point
  /// refetching data for screens nobody can see.
  void pause() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Call when the app returns to the foreground. Does one immediate
  /// refresh (in case something changed while backgrounded) and
  /// restarts the periodic poll.
  void resume() {
    final container = _container;
    if (container == null) return;
    _silentRefreshAll(container);
    _startTimer(container);
  }

  Future<void> init(ProviderContainer container) async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
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
      }
      _silentRefreshAll(container);
    });

    // Fallback for when the backend doesn't (or can't) send a push for
    // every change: every 2 minutes while the app is open and in the
    // foreground, quietly re-check everything the same way a push
    // would. Paused automatically while the app is backgrounded (see
    // [pause]/[resume]) so it doesn't burn battery/data or contend with
    // the UI thread when nothing is even visible.
    _startTimer(container);

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM device token: $token');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  /// Re-fetches notifications, wallet, tournaments, and home feed data
  /// in the background. FutureProviders keep showing their last-known
  /// data while re-fetching (AsyncValue.when's skipLoadingOnRefresh
  /// defaults to true), so nothing on screen flashes or reloads
  /// visibly — it just quietly becomes current.
  void _silentRefreshAll(ProviderContainer container) {
    container.invalidate(unreadNotificationCountProvider);
    container.read(notificationsProvider.notifier).refresh();

    container.invalidate(walletProvider);
    container.invalidate(recentTransactionsProvider);
    container.invalidate(walletSummaryProvider);

    container.invalidate(liveTournamentsProvider);
    container.invalidate(upcomingTournamentsProvider);
    container.invalidate(featuredLiveTournamentProvider);
    container.invalidate(allTournamentsProvider);
    container.invalidate(liveTournamentsCountProvider);

    container.invalidate(bannersProvider);
    container.invalidate(currentUserProvider);
  }
}
