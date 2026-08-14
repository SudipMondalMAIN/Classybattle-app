import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../providers/tournament_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../home/section_header.dart';

class YourTournamentsSection extends ConsumerWidget {
  const YourTournamentsSection({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myTournamentStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Your Tournaments', onViewAll: onViewAll),
        const SizedBox(height: 14),
        statsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.purpleSoft),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Couldn\'t load your stats',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          data: (stats) {
            if (stats == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Log in to see your joined tournaments, wins and winnings.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              );
            }
            return GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              blurSigma: 0, // per-row card in a scrolling list -- see live_tournament_card.dart
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.purple,
                      value: '${stats.joined}',
                      label: 'Joined',
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _Stat(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.gold,
                      value: '${stats.won}',
                      label: 'Won',
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _Stat(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.success,
                      value: formatRupees(stats.totalWinnings),
                      label: 'Total Winnings',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppColors.glassBorder,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
