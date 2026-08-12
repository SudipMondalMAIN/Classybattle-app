import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version_check.dart';
import '../theme/app_theme.dart';

/// Blocking screen shown when backend `/app/version/check` says
/// force_update = true. There is no way to dismiss/skip this —
/// PopScope swallows the back gesture.
class ForceUpdateScreen extends StatelessWidget {
  final AppVersionCheck info;

  const ForceUpdateScreen({super.key, required this.info});

  Future<void> _openStore() async {
    final uri = Uri.tryParse(info.updateUrl);
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
                    child: const Icon(Icons.system_update_alt_rounded,
                        color: AppColors.purpleSoft, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    info.updateTitle.isNotEmpty
                        ? info.updateTitle
                        : 'Update Required',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info.updateMessage.isNotEmpty
                        ? info.updateMessage
                        : 'A new version of ClassyBattle is required to continue.',
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
                          onTap: _openStore,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Update Now',
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
