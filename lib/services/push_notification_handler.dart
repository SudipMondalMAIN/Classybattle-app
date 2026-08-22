import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/notification_providers.dart';
import '../providers/home_providers.dart';
import '../providers/wallet_providers.dart';
import '../providers/tournament_providers.dart';
import 'notification_service.dart' show notificationService;
import 'home_service.dart' show UnauthenticatedException;
import '../core/token_storage.dart';
import '../core/navigation.dart';
import '../models/notification_model.dart';
import '../widgets/notifications/notification_router.dart';

/// Top-level handler required by FirebaseMessaging.onBackgroundMessage --
/// must not be a class member (isolate entry point requirement).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// Wires up foreground FCM messages to a local notification so they're
/// visible while the app is open, and registers this device's FCM token
/// with the backend (POST /notifications/device-tokens) so it actually
/// receives pushes -- on init (if already logged in), right after
/// login/signup (via [registerTokenIfNeeded]), and again whenever FCM
/// rotates the token.
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
  String? _lastKnownToken;

  static const _pollInterval = Duration(minutes: 2);

  /// Sends [token] to the backend (POST /notifications/device-tokens) if
  /// -- and only if -- a user is currently logged in. Safe to call
  /// whenever we have a token: at startup (before login, this is a
  /// no-op), right after login/signup succeed, and on every FCM token
  /// refresh. Best-effort: failures are logged, never thrown, so a
  /// flaky network never breaks app startup or login.
  Future<void> _registerWithBackend(String token) async {
    if (!await TokenStorage.hasSession()) return;
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      await notificationService.registerDeviceToken(token, platform: platform);
      debugPrint('FCM device token registered with backend');
    } on UnauthenticatedException {
      // Session expired/invalid; nothing to do, will retry next refresh.
    } on DioException catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  /// Call right after login/signup completes (i.e. right after tokens
  /// are persisted). At that point we already have the FCM token from
  /// [init] cached in [_lastKnownToken] -- this just pushes it to the
  /// backend now that we're authenticated.
  Future<void> registerTokenIfNeeded() async {
    final token = _lastKnownToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    _lastKnownToken = token;
    await _registerWithBackend(token);
  }

  /// Builds the same routing decision the in-app notification list uses
  /// (see notification_router.dart), but from a raw FCM data payload
  /// instead of a fetched [NotificationModel] -- so tapping a push from
  /// the OS tray lands on the same screen as tapping it in-app.
  ///
  /// [data] is whatever the backend sent as the FCM message's `data`
  /// map (event_type, notification_id, and flattened meta_data such as
  /// tournament_id/transaction_id -- see
  /// NotificationDispatchService._send_push_best_effort).
  void _navigateForPushData(Map<String, dynamic> data) {
    final context = navigatorKey.currentState?.context;
    if (context == null) return;

    final model = NotificationModel(
      id: data['notification_id']?.toString() ?? '',
      title: '',
      body: '',
      eventType: NotificationEventType.fromRaw(data['event_type'] as String?),
      isRead: true,
      createdAt: DateTime.now(),
      metaData: data,
    );
    navigateForNotification(context, model);

    // Best-effort: keep the in-app list's unread state consistent with
    // what the user just opened from the tray. Failures are harmless --
    // the list will still reflect it next silent refresh.
    final notificationId = data['notification_id'];
    if (notificationId != null) {
      notificationService.markRead(notificationId.toString()).catchError((_) {});
    }
  }

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

    // User tapped a push while the app was backgrounded (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateForPushData(message.data);
    });

    // App was fully closed and got opened *by* tapping a push -- the
    // tap that launched the app doesn't fire onMessageOpenedApp, so it
    // has to be checked for separately. The navigator/widget tree may
    // not be mounted yet at this point, so defer to the first frame.
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message == null) return;
      // SplashScreen holds the screen for ~2.6s then does its own
      // pushReplacement to Home -- firing right after the first frame
      // would get clobbered by that. Wait it out first so this lands
      // on top of Home instead of underneath it.
      await Future.delayed(const Duration(milliseconds: 3000));
      _navigateForPushData(message.data);
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
      if (token != null) {
        _lastKnownToken = token;
        // No-op if not logged in yet (e.g. fresh install, splash
        // screen) -- registerTokenIfNeeded() covers that case right
        // after login/signup.
        await _registerWithBackend(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // FCM rotates the token occasionally (app reinstall, data clear,
    // token expiry, etc). Without this listener a rotated token is
    // never sent to the backend and push silently stops working.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _lastKnownToken = newToken;
      _registerWithBackend(newToken);
    });
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