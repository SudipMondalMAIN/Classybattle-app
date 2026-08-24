import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/maintenance_check.dart';
import '../theme/app_theme.dart';

/// Blocking screen shown when backend `/app/maintenance/check` says
/// is_enabled = true. There is no way to dismiss/skip this —
/// PopScope swallows the back gesture. Deliberately distinct from
/// ForceUpdateScreen (different icon, different button/action —
/// "Check Status" opens the status page instead of an app store).
class MaintenanceScreen extends StatelessWidget {
  final MaintenanceCheck info;

  const MaintenanceScreen({super.key, required this.info});

  Future<void> _openStatusPage() async {
    final uri = Uri.tryParse(info.statusUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundGradientTop,
                AppColors.backgroundGradientBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purple.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.purpleSoft.withValues(alpha: 0.6),
                        width: 1.4,
                      ),
                    ),
                    child: const Icon(Icons.construction_rounded,
                        color: AppColors.purpleSoft, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    info.title.isNotEmpty ? info.title : 'Under Maintenance',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info.message.isNotEmpty
                        ? info.message
                        : 'ClassyBattle is currently undergoing scheduled '
                            'maintenance. Please check back shortly.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleButton,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _openStatusPage,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Check Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
