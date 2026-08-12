import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import 'live_tournament_card.dart';
import 'section_header.dart';

class LiveTournamentsSection extends ConsumerWidget {
  const LiveTournamentsSection({
    super.key,
    required this.onViewAll,
    required this.onJoinTap,
  });

  final VoidCallback onViewAll;
  final void Function(String tournamentId) onJoinTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(liveTournamentsProvider);
    final gamesAsync = ref.watch(gamesByIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Live Tournaments', onViewAll: onViewAll),
        ),
        const SizedBox(height: 14),
        tournamentsAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.purpleSoft),
            ),
          ),
          error: (e, __) => const _InlineMessage('Couldn\'t load live tournaments'),
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return const _InlineMessage('No live tournaments right now');
            }
            final games = gamesAsync.valueOrNull ?? const {};
            return SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tournaments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final t = tournaments[i];
                  return LiveTournamentCard(
                    tournament: t,
                    game: games[t.gameId],
                    onJoinTap: () => onJoinTap(t.id),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}
