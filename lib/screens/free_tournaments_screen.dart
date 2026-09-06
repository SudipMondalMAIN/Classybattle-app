import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/home/format_page_banner.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/upcoming_tournament_row.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tournament_details_screen.dart';
import 'wallet_screen.dart';

/// Dedicated browse page for Free tournaments (format=free).
/// Separate from the main Tournaments screen/tabs, same pattern as
/// CustomTournamentsScreen -- tapping a tournament opens the same
/// TournamentDetailsScreen used everywhere else.
class FreeTournamentsScreen extends ConsumerStatefulWidget {
  const FreeTournamentsScreen({super.key});

  @override
  ConsumerState<FreeTournamentsScreen> createState() => _FreeTournamentsScreenState();
}

class _FreeTournamentsScreenState extends ConsumerState<FreeTournamentsScreen> {

  static const String _format = 'free';

  Future<void> _refresh() async {
    ref.invalidate(formatTournamentsProvider(_format));
    ref.invalidate(gamesByIdProvider);
    await Future.wait(
      [
        ref.read(formatTournamentsProvider(_format).future),
        ref.read(gamesByIdProvider.future),
      ].map((f) => f.catchError((_) => null)),
    );
  }

  void _openTournament(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentDetailsScreen(tournamentId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(formatTournamentsProvider(_format));
    final gamesAsync = ref.watch(gamesByIdProvider);

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
          child: RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.background,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HeaderBar(
                    onNotificationsTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    onWalletTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    ),
                    onProfileTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: _TitleBlock()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: FormatPageBanner(
                      assetPath: 'assets/banners/free_tournaments_banner.jpg',
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: tournamentsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.purpleSoft,
                          ),
                        ),
                      ),
                    ),
                    error: (_, __) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Couldn\'t load Free tournaments',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    data: (tournaments) {
                      final filtered = tournaments;
                      if (filtered.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No Free tournaments yet',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      final games = gamesAsync.valueOrNull ?? const {};
                      return SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final t = filtered[i];
                          return GestureDetector(
                            onTap: () => _openTournament(t.id),
                            child: UpcomingTournamentRow(
                              tournament: t,
                              game: games[t.gameId],
                              onJoinTap: () => _openTournament(t.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Free Tournaments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'No entry fee, all skill',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}
