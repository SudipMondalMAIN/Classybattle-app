import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({
    super.key,
    required this.joined,
    required this.won,
    required this.totalWinnings,
    required this.winRate,
  });

  final int joined;
  final int won;
  final double totalWinnings;
  final double? winRate;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.purple,
              value: '$joined',
              label: 'Tournaments\nJoined',
            ),
          ),
          _Divider(),
          Expanded(
            child: _Stat(
              icon: Icons.star_rounded,
              iconColor: AppColors.gold,
              value: '$won',
              label: 'Tournaments\nWon',
            ),
          ),
          _Divider(),
          Expanded(
            child: _Stat(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.success,
              value: formatRupees(totalWinnings),
              label: 'Total\nWinnings',
            ),
          ),
          _Divider(),
          Expanded(
            child: _Stat(
              icon: Icons.workspace_premium_rounded,
              iconColor: const Color(0xFF3DB4FF),
              value: winRate == null ? '—' : '${winRate!.round()}%',
              label: 'Win Rate',
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: AppColors.glassBorder,
    );
  }
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
