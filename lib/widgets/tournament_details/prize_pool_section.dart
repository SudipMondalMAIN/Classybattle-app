import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/prize_pool_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class PrizePoolSection extends StatelessWidget {
  const PrizePoolSection({super.key, required this.prizePool, this.fallbackTotal});

  /// Real configured pool -- null when the organizer hasn't set one up.
  final PrizePoolModel? prizePool;

  /// Tournament.prize_pool (total amount) shown as a graceful fallback
  /// when no rank-by-rank distribution has been configured yet.
  final double? fallbackTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.purpleSoft),
            const SizedBox(width: 8),
            const Text(
              'Prize Pool',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (prizePool != null && prizePool!.ranks.length > 3)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Prize Distribution',
                    style: TextStyle(
                      color: AppColors.purpleSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.purpleSoft),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (prizePool == null || prizePool!.ranks.isEmpty)
          GlassContainer(
            borderRadius: 14,
            padding: const EdgeInsets.all(14),
            child: Text(
              fallbackTotal != null && fallbackTotal! > 0
                  ? 'Total prize pool: ${formatRupees(fallbackTotal!)}. Rank-wise distribution hasn\'t been published yet.'
                  : 'Prize distribution hasn\'t been published for this tournament yet.',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          )
        else
          Row(
            children: prizePool!.ranks.take(3).map((rank) {
              final amount = prizePool!.payoutForRank(rank);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: rank == prizePool!.ranks.take(3).last ? 0 : 10),
                  child: _PrizeTile(rank: rank, amount: amount),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _PrizeTile extends StatelessWidget {
  const _PrizeTile({required this.rank, required this.amount});

  final int rank;
  final double amount;

  static const _medalColors = {
    1: AppColors.gold,
    2: Color(0xFFC7CBD1),
    3: Color(0xFFCD7F32),
  };

  static const _medalIcons = {
    1: Icons.emoji_events,
    2: Icons.workspace_premium,
    3: Icons.military_tech,
  };

  static const _ordinal = {1: '1st', 2: '2nd', 3: '3rd'};

  @override
  Widget build(BuildContext context) {
    final color = _medalColors[rank] ?? AppColors.purpleSoft;
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      borderColor: color.withValues(alpha: 0.4),
      child: Column(
        children: [
          Icon(_medalIcons[rank] ?? Icons.star, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            '${_ordinal[rank] ?? '${rank}th'} Prize',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupees(amount),
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
