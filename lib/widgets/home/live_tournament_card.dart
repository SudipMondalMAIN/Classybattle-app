import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/game_model.dart';
import '../../models/tournament_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../common/network_image_box.dart';

class LiveTournamentCard extends StatelessWidget {
  const LiveTournamentCard({
    super.key,
    required this.tournament,
    required this.game,
  });

  final TournamentModel tournament;
  final GameModel? game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      child: GlassContainer(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        // Real-time blur here is pure cost with no visible payoff -- this
        // card sits over a flat background gradient (not detailed content),
        // and it's one of many rendered per scroll frame in a horizontal
        // list. A flat fill looks the same and removes a BackdropFilter
        // pass per card per frame.
        blurSigma: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 600 / 410,
                  child: NetworkImageBox(
                    url: tournament.bannerUrl ?? game?.iconUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    cacheHeight: 410,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: AppColors.live),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (game?.name ?? '').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.purpleSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tournament.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: tournament.prizeBadgeLabel,
                          value: tournament.prizeType == 'per_kill'
                              ? '${formatRupees(tournament.prizeBadgeAmount)}/kill'
                              : formatRupees(tournament.prizeBadgeAmount),
                          valueColor: AppColors.gold,
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'Entries',
                          value:
                              '${tournament.currentPlayers} / ${tournament.maxPlayers}',
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _EntryFeeBadge(entryFee: tournament.entryFee),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${tournament.slotsLeft} slots left',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // Already live -- joining is closed, so this is
                      // just a "view details" affordance, not a CTA.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glassFillStrong,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 10, color: AppColors.textPrimary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryFeeBadge extends StatelessWidget {
  const _EntryFeeBadge({required this.entryFee});
  final double entryFee;

  @override
  Widget build(BuildContext context) {
    final isFree = entryFee <= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.success.withValues(alpha: 0.14)
            : AppColors.purple.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFree
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.purple.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFree ? Icons.celebration_rounded : Icons.currency_rupee_rounded,
            size: 14,
            color: isFree ? AppColors.success : AppColors.purpleSoft,
          ),
          const SizedBox(width: 4),
          Text(
            isFree ? 'FREE ENTRY' : 'Entry ${formatRupees(entryFee)}',
            style: TextStyle(
              color: isFree ? AppColors.success : AppColors.purpleSoft,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
