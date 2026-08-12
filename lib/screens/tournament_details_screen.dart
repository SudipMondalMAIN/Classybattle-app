import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/tournament_details/details_header_bar.dart';
import '../widgets/tournament_details/join_section.dart';
import '../widgets/tournament_details/prize_pool_section.dart';
import '../widgets/tournament_details/room_details_section.dart';
import '../widgets/tournament_details/tournament_hero.dart';
import '../widgets/tournament_details/tournament_info_card.dart';
import '../widgets/tournament_details/tournament_rules_section.dart';

class TournamentDetailsScreen extends ConsumerWidget {
  const TournamentDetailsScreen({super.key, required this.tournamentId});

  final String tournamentId;

  void _notImplemented(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what — coming soon')));
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(tournamentDetailProvider(tournamentId));
    ref.invalidate(tournamentPrizePoolProvider(tournamentId));
    ref.invalidate(myRegistrationProvider(tournamentId));
    ref.invalidate(walletProvider);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tournamentDetailProvider(tournamentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientTop,
              AppColors.backgroundGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              DetailsHeaderBar(
                onNotificationsTap: () => _notImplemented(context, 'Notifications'),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.purple,
                  backgroundColor: AppColors.background,
                  onRefresh: () => _refresh(ref),
                  child: detailAsync.when(
                    loading: () => const _CenteredLoader(),
                    error: (e, __) => _CenteredError(
                      message: 'Couldn\'t load this tournament.',
                      onRetry: () => ref.invalidate(tournamentDetailProvider(tournamentId)),
                    ),
                    data: (tournament) {
                      final gamesAsync = ref.watch(gamesByIdProvider);
                      final game = gamesAsync.valueOrNull?[tournament.gameId];
                      final gameMode =
                          ref.watch(tournamentGameModeProvider(tournament.modeId)).valueOrNull;
                      final map = ref.watch(tournamentMapProvider(tournament.mapId)).valueOrNull;
                      final prizePoolAsync =
                          ref.watch(tournamentPrizePoolProvider(tournament.id));

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: [
                          TournamentHero(
                            tournament: tournament,
                            game: game,
                            gameMode: gameMode,
                            map: map,
                          ),
                          const SizedBox(height: 16),
                          JoinSection(tournament: tournament),
                          const SizedBox(height: 16),
                          GlassContainer(
                            borderRadius: 18,
                            padding: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TournamentInfoCard(
                                tournament: tournament,
                                game: game,
                                gameMode: gameMode,
                                map: map,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(16),
                            child: RoomDetailsSection(tournament: tournament),
                          ),
                          const SizedBox(height: 16),
                          GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(16),
                            child: PrizePoolSection(
                              prizePool: prizePoolAsync.valueOrNull,
                              fallbackTotal: tournament.prizePool,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(16),
                            child: TournamentRulesSection(rules: tournament.rules),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator(color: AppColors.purpleSoft)),
      ],
    );
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        Icon(Icons.error_outline_rounded, color: AppColors.textMuted, size: 36)
            .let((w) => Center(child: w)),
        const SizedBox(height: 12),
        Center(
          child: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        const SizedBox(height: 14),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purpleSoft,
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
