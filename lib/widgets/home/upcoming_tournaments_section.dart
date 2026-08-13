import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import 'section_header.dart';
import 'upcoming_tournament_row.dart';

class UpcomingTournamentsSection extends ConsumerWidget {
  const UpcomingTournamentsSection({
    super.key,
    required this.onViewAll,
    required this.onJoinTap,
  });

  final VoidCallback onViewAll;
  final void Function(String tournamentId) onJoinTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(upcomingTournamentsProvider);
    final gamesAsync = ref.watch(gamesByIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Upcoming Tournaments', onViewAll: onViewAll),
        const SizedBox(height: 14),
        tournamentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.purpleSoft),
            ),
          ),
          error: (e, __) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Couldn\'t load upcoming tournaments',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No upcoming tournaments yet',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              );
            }
            final games = gamesAsync.valueOrNull ?? const {};
            return Column(
              children: tournaments
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => onJoinTap(t.id),
                        child: UpcomingTournamentRow(
                          tournament: t,
                          game: games[t.gameId],
                          onJoinTap: () => onJoinTap(t.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
