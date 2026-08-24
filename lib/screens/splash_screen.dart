import 'package:flutter/material.dart';
import '../models/app_version_check.dart';
import '../models/maintenance_check.dart';
import '../services/app_version_service.dart';
import '../services/maintenance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/splash/animated_splash_scene.dart';
import 'force_update_screen.dart';
import 'home_screen.dart';
import 'maintenance_screen.dart';

/// App entry splash: plays the ~2.6s cinematic scene while the real
/// backend maintenance check (GET /app/maintenance/check, see
/// backend/app/api/v1/maintenance_routes.py) and version check
/// (GET /app/version/check, see backend/app/api/v1/app_version_routes.py)
/// run in parallel, then routes to MaintenanceScreen, ForceUpdateScreen,
/// or HomeScreen accordingly. Maintenance takes priority over
/// force-update: if the whole app is down for maintenance, there's no
/// point telling the user to go update first.
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

    // Real backend calls — never fabricated. Run in parallel since
    // they're independent; each falls back to a no-op (never blocks
    // the user) if its own request fails.
    final results = await Future.wait([
      MaintenanceService.check(),
      AppVersionService.check(),
    ]);
    final maintenanceCheck = results[0] as MaintenanceCheck;
    final versionCheck = results[1] as AppVersionCheck;

    // Keep the cinematic reveal on screen for its full intended
    // duration even if the network calls were fast, so the animation
    // never feels cut short.
    final elapsed = stopwatch.elapsed;
    if (elapsed < _minSplashTime) {
      await Future.delayed(_minSplashTime - elapsed);
    }

    if (!mounted) return;
    _navigate(maintenanceCheck, versionCheck);
  }

  Future<void> _navigate(
    MaintenanceCheck maintenanceInfo,
    AppVersionCheck versionInfo,
  ) async {
    // Maintenance takes priority: if the whole app is down, force-update
    // is irrelevant.
    if (maintenanceInfo.isEnabled) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MaintenanceScreen(info: maintenanceInfo),
        ),
      );
      return;
    }

    if (versionInfo.forceUpdate) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ForceUpdateScreen(info: versionInfo),
        ),
      );
      return;
    }

    // Guest mode: always land on Home whether or not the user is
    // logged in. Login/signup is reachable from the Profile tab.
    if (!mounted) return;
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
