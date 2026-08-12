import 'package:flutter/material.dart';
import '../models/app_version_check.dart';
import '../services/app_version_service.dart';
import '../theme/app_theme.dart';
import '../widgets/splash/animated_splash_scene.dart';
import 'force_update_screen.dart';
import 'home_screen.dart';

/// App entry splash: plays the ~2.6s cinematic scene while the real
/// backend version check (GET /app/version/check, see
/// backend/app/api/v1/app_version_routes.py) runs in parallel, then
/// routes to ForceUpdateScreen or HomeScreen accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplashTime = Duration(milliseconds: 2600);

  @override
  void initState() {
    super.initState();
    _startup();
  }

  Future<void> _startup() async {
    final stopwatch = Stopwatch()..start();

    // Real backend call — never fabricated. Falls back to a no-op
    // (never blocks the user) if the request itself fails.
    final versionCheck = await AppVersionService.check();

    // Keep the cinematic reveal on screen for its full intended
    // duration even if the network call was fast, so the animation
    // never feels cut short.
    final elapsed = stopwatch.elapsed;
    if (elapsed < _minSplashTime) {
      await Future.delayed(_minSplashTime - elapsed);
    }

    if (!mounted) return;
    _navigate(versionCheck);
  }

  void _navigate(AppVersionCheck info) {
    if (info.forceUpdate) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ForceUpdateScreen(info: info)),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const AnimatedSplashScene(),
    );
  }
}
