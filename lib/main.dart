import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_handler.dart';
import 'core/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Created explicitly (instead of letting ProviderScope make one) so
  // PushNotificationHandler can read/invalidate providers directly when
  // a push arrives -- that's what makes auto-refresh possible even
  // before any screen using those providers has been built.
  final container = ProviderContainer();

  // Requires android/app/google-services.json — see FIREBASE_SETUP.md.
  // Wrapped so a missing/misconfigured file doesn't hard-crash the app;
  // push notifications just won't work until it's added correctly.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationHandler.instance.init(container);
  } catch (e) {
    debugPrint('Firebase init failed (check google-services.json): $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ClassyBattleApp(),
    ),
  );
}

class ClassyBattleApp extends StatefulWidget {
  const ClassyBattleApp({super.key});

  @override
  State<ClassyBattleApp> createState() => _ClassyBattleAppState();
}

class _ClassyBattleAppState extends State<ClassyBattleApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop the 60s background poll while the app isn't visible, and
    // catch up with one refresh the moment it's visible again -- this
    // is the single biggest lever for "app feels smooth": no silent
    // network/rebuild work fights the UI thread when the user is
    // actually looking at the screen and scrolling.
    switch (state) {
      case AppLifecycleState.resumed:
        PushNotificationHandler.instance.resume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        PushNotificationHandler.instance.pause();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ClassyBattle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
