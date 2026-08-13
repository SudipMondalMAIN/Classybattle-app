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
    final chips = <String>[
      if (tournament.registrationMode == 'solo') 'Solo' else 'Squad',
      if (gameMode != null) gameMode!.name,
      if (map != null) map!.name,
    ];

    return Container(
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
              height: 340,
              width: double.infinity,
              child: NetworkImageBox(
                url: tournament.bannerUrl ?? tournament.coverUrl,
                fit: BoxFit.cover,
                cacheWidth: 800,
                cacheHeight: 680,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(top: 14, left: 14, child: _liveBadge()),
            Positioned(
              top: 14,
              right: 14,
              child: SizedBox(width: 150, child: _statsPanel()),
            ),
            Positioned(
              left: 16,
              right: 170,
              bottom: 16,
              child: Column(
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
                  const SizedBox(height: 4),
                  Text(
                    tournament.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
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
                        color: Colors.white70,
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
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: Colors.white,
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
            ),
          ],
        ),
      ),
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

  Widget _statsPanel() {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // Lighter blur + more transparent fill so the banner image stays
      // visible behind the prize pool / entries / time-left panel
      // instead of being washed out by a heavy frosted-glass blur.
      blurSigma: 4,
      fillColor: Colors.black.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ShadowedLabel('PRIZE POOL'),
          const SizedBox(height: 2),
          Text(
            formatRupees(tournament.prizePool),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 10),
          const _ShadowedLabel('ENTRIES'),
          const SizedBox(height: 2),
          Text(
            '${tournament.currentPlayers} / ${tournament.maxPlayers}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 10),
          const _ShadowedLabel('TIME LEFT'),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
              ),
              const SizedBox(width: 4),
              Text(
                _timeLeftLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShadowedLabel extends StatelessWidget {
  const _ShadowedLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
      ),
    );
  }
}
