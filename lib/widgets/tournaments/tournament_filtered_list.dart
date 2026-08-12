import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_providers.dart';
import '../../providers/tournament_providers.dart';
import '../../theme/app_theme.dart';
import '../home/upcoming_tournament_row.dart';

/// Full-width list used for the Live / Upcoming / Completed / My
/// Tournaments tabs -- reuses the same row styling as the Home
/// screen's Upcoming section, driven entirely by real backend data
/// for whichever tab is selected.
class TournamentFilteredList extends ConsumerWidget {
  const TournamentFilteredList({super.key, required this.onOpenTournament});

  final void Function(String tournamentId) onOpenTournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentsForSelectedTabProvider);
    final gamesAsync = ref.watch(gamesByIdProvider);
    final tab = ref.watch(selectedTournamentTabProvider);

    return tournamentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purpleSoft),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Couldn\'t load tournaments',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      ),
      data: (tournaments) {
        if (tournaments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                tab == TournamentTab.mine
                    ? 'You haven\'t joined any tournaments yet'
                    : 'No tournaments found',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
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
                    onTap: () => onOpenTournament(t.id),
                    child: UpcomingTournamentRow(
                      tournament: t,
                      game: games[t.gameId],
                      onJoinTap: () => onOpenTournament(t.id),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
