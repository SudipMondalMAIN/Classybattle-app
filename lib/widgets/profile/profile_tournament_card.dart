import 'package:flutter/material.dart';
import '../../models/game_model.dart';
import '../../models/tournament_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../common/network_image_box.dart';

class ProfileTournamentCard extends StatelessWidget {
  const ProfileTournamentCard({
    super.key,
    required this.tournament,
    required this.game,
    required this.participantStatus,
    required this.onTap,
  });

  final TournamentModel tournament;
  final GameModel? game;
  final String participantStatus;
  final VoidCallback onTap;

  ({String label, Color color}) get _badge {
    if (participantStatus == 'cancelled' || tournament.status == 'cancelled') {
      return (label: 'Cancelled', color: AppColors.textMuted);
    }
    switch (tournament.status) {
      case 'live':
        return (label: 'In Progress', color: const Color(0xFF3DB4FF));
      case 'completed':
        return (label: 'Completed', color: AppColors.success);
      case 'scheduled':
      default:
        return (label: 'Upcoming', color: AppColors.purpleSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: NetworkImageBox(
                  url: tournament.bannerUrl,
                  borderRadius: BorderRadius.circular(12),
                  cacheWidth: 128,
                  cacheHeight: 128,
                ),
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
                      fontSize: 10,
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
                      const Icon(Icons.groups_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${tournament.currentPlayers} / ${tournament.maxPlayers} Joined',
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
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badge.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      color: badge.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
