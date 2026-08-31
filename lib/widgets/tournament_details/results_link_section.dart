import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

/// Small banner on the Tournament Details page pointing users to the
/// public results website, where they can look up results for all
/// tournaments (not just this one).
class ResultsLinkSection extends StatelessWidget {
  const ResultsLinkSection({super.key});

  static const _resultsUrl = 'https://results.classybattle.online/';

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(_resultsUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the results site')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(context),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.leaderboard_rounded,
                size: 17,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'You can check all tournaments results here',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
