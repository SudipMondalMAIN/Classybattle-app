import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_version_check.dart';
import '../../theme/app_theme.dart';

/// Dismissible "a new version is available" prompt -- shown on Home
/// when the backend's /app/version/check says update_available=true
/// but force_update=false (an optional update, unlike ForceUpdateScreen
/// which blocks the app entirely). The user can tap "Update" to open
/// the store link, or "Later" / dismiss to keep using the current
/// version.
Future<void> showSoftUpdateDialog(BuildContext context, AppVersionCheck info) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        info.updateTitle.isNotEmpty ? info.updateTitle : 'Update Available',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        info.updateMessage.isNotEmpty
            ? info.updateMessage
            : 'A new version of ClassyBattle is available.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Later',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final uri = Uri.tryParse(info.updateUrl);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text(
            'Update',
            style: TextStyle(
              color: AppColors.purpleSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
