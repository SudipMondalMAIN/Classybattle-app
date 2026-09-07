import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/game_mode_model.dart';
import '../../models/game_model.dart';
import '../../models/map_model.dart';
import '../../models/tournament_detail_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../common/network_image_box.dart';

class TournamentHero extends StatelessWidget {
  const TournamentHero({
    super.key,
    required this.tournament,
    required this.game,
    required this.gameMode,
    required this.map,
  });

  final TournamentDetailModel tournament;
  final GameModel? game;
  final GameModeModel? gameMode;
  final MapModel? map;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (tournament.registrationMode == 'solo') 'Solo' else 'Squad',
      if (gameMode != null) gameMode!.name,
      if (map != null) map!.name,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.16),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(
                      color: AppColors.glassBorder.withValues(alpha: 0.08),
                      child: NetworkImageBox(
                        url:
                            tournament.bannerUrl ??
                            tournament.coverUrl ??
                            game?.iconUrl,
                        fit: BoxFit.contain,
                        cacheWidth: 800,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(top: 14, left: 14, child: _liveBadge()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (game != null)
              Text(
                game!.name.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              tournament.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            if (tournament.description != null &&
                tournament.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                tournament.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glassBorder.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _liveBadge() {
    if (!tournament.isLive) {
      final label =
          tournament.status[0].toUpperCase() + tournament.status.substring(1);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.live),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prize / Entry Fee / Entries / Time Left, laid out horizontally in
/// one full-width glass bar -- same transparent glass look the panel
/// used to have on the banner, just moved below the Join button (full
/// width, same footprint as that button) so the banner itself stays
/// clean and uncluttered.
class TournamentStatsBar extends StatelessWidget {
  const TournamentStatsBar({super.key, required this.tournament});

  final TournamentDetailModel tournament;

  String _timeLeftLabel() {
    final d = tournament.timeLeft;
    if (d == null) return '—';
    if (d == Duration.zero) return 'Ending';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: tournament.prizeBadgeLabel.toUpperCase(),
              value: tournament.prizeType == 'per_kill'
                  ? '${formatRupees(tournament.prizeBadgeAmount)}/kill'
                  : formatRupees(tournament.prizeBadgeAmount),
              valueColor: AppColors.gold,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              label: 'ENTRY FEE',
              value: tournament.isFree
                  ? 'FREE'
                  : formatRupees(tournament.entryFee),
              valueColor: tournament.isFree
                  ? AppColors.success
                  : AppColors.textPrimary,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              label: 'ENTRIES',
              value: '${tournament.currentPlayers}/${tournament.maxPlayers}',
              valueColor: AppColors.textPrimary,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              label: 'TIME LEFT',
              value: _timeLeftLabel(),
              valueColor: AppColors.textPrimary,
              icon: Icons.access_time_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.glassBorder,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: valueColor),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
