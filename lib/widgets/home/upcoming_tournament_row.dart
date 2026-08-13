import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/game_model.dart';
import '../../models/tournament_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../common/network_image_box.dart';

/// Note: the backend's Tournament has no start-date/time field (join
/// is instant while status == scheduled -- see TournamentModel's
/// doc comment), so unlike the reference mock this row shows real
/// slot/entry-fee info instead of a fabricated date/time.
class UpcomingTournamentRow extends StatelessWidget {
  const UpcomingTournamentRow({
    super.key,
    required this.tournament,
    required this.game,
    required this.onJoinTap,
  });

  final TournamentModel tournament;
  final GameModel? game;
  final VoidCallback onJoinTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: NetworkImageBox(
              url: tournament.bannerUrl,
              borderRadius: BorderRadius.circular(12),
              cacheWidth: 128,
              cacheHeight: 128,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.groups_2_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${tournament.currentPlayers}/${tournament.maxPlayers} joined',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.payments_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      tournament.entryFee > 0
                          ? '${formatRupees(tournament.entryFee)} entry'
                          : 'Free entry',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Prize Pool',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              Text(
                formatRupees(tournament.prizePool),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onJoinTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleButton,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
