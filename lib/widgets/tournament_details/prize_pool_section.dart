import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/tournament_detail_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

/// Shows how this tournament actually pays out winners, driven directly
/// by the tournament's own prize_type config (set by admin at schedule
/// time, editable per-slot afterwards) -- no separate "publish" step
/// needed, unlike the older rank-only PrizePool/payout system.
class PrizePoolSection extends StatelessWidget {
  const PrizePoolSection({super.key, required this.tournament});

  final TournamentDetailModel tournament;

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
            _PrizeTypeBadge(prizeType: tournament.prizeType),
          ],
        ),
        const SizedBox(height: 12),
        _buildBody(context),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (tournament.prizeType) {
      case 'per_kill':
        return _PerKillCard(amount: tournament.perKillAmount);
      case 'win':
        return _WinCard(amount: tournament.winAmount);
      case 'rank':
      default:
        return _RankRow(rules: tournament.rankPrizeRules, fallbackTotal: tournament.prizePool);
    }
  }
}

class _PrizeTypeBadge extends StatelessWidget {
  const _PrizeTypeBadge({required this.prizeType});
  final String prizeType;

  @override
  Widget build(BuildContext context) {
    final label = switch (prizeType) {
      'per_kill' => 'Per Kill',
      'win' => 'Win Bonus',
      _ => 'Rank-wise',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.purpleSoft,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Rank-based: top 3 tiles side by side, same look as before.
class _RankRow extends StatelessWidget {
  const _RankRow({required this.rules, required this.fallbackTotal});

  final List<RankPrizeRule> rules;
  final double fallbackTotal;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(14),
        child: Text(
          fallbackTotal > 0
              ? 'Total prize pool: ${formatRupees(fallbackTotal)}. Rank-wise distribution hasn\'t been published yet.'
              : 'Prize distribution hasn\'t been published for this tournament yet.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      );
    }

    final sorted = [...rules]..sort((a, b) => a.rank.compareTo(b.rank));
    final top3 = sorted.take(3).toList();

    return Row(
      children: [
        for (var i = 0; i < top3.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == top3.length - 1 ? 0 : 10),
              child: _PrizeTile(rank: top3[i].rank, amount: top3[i].amount),
            ),
          ),
      ],
    );
  }
}

/// Per-kill: single wide card, e.g. "₹10 per kill".
class _PerKillCard extends StatelessWidget {
  const _PerKillCard({required this.amount});
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      borderColor: AppColors.gold.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed_rounded, color: AppColors.gold, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Per Kill Reward',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  amount != null
                      ? '${formatRupees(amount!)} / kill'
                      : 'Not configured yet',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Win-only: single wide card, e.g. "₹500 for the win".
class _WinCard extends StatelessWidget {
  const _WinCard({required this.amount});
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      borderColor: AppColors.gold.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Winner Bonus',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  amount != null ? formatRupees(amount!) : 'Not configured yet',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
