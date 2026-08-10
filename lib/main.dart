import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Requires android/app/google-services.json — see FIREBASE_SETUP.md.
  // Wrapped so a missing/misconfigured file doesn't hard-crash the app;
  // push notifications just won't work until it's added correctly.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationHandler.instance.init();
  } catch (e) {
    debugPrint('Firebase init failed (check google-services.json): $e');
  }

  runApp(const ProviderScope(child: ClassyBattleApp()));
}

class ClassyBattleApp extends StatelessWidget {
  const ClassyBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
