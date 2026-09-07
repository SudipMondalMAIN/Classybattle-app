import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/skeleton.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/upcoming_tournament_row.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tournament_details_screen.dart';
import 'wallet_screen.dart';

/// Dedicated "My Tournaments" screen -- reached from the bottom nav.
/// Unlike [TournamentsScreen] (which has Live/Upcoming/All tabs and a
/// search bar), this screen has exactly one job: show the tournaments
/// the current user has actually joined. Nothing else is listed here.
class MyTournamentsScreen extends ConsumerWidget {
  const MyTournamentsScreen({super.key});

  void _openTournament(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentDetailsScreen(tournamentId: id),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myJoinedTournamentsProvider);
    ref.invalidate(gamesByIdProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(currentUserProvider);
    await Future.wait([
      ref.read(myJoinedTournamentsProvider.future),
      ref.read(gamesByIdProvider.future),
      ref.read(walletProvider.future),
      ref.read(currentUserProvider.future),
    ].map((f) => f.catchError((_) => null)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedAsync = ref.watch(myJoinedTournamentsProvider);
    final gamesAsync = ref.watch(gamesByIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
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
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.background,
            onRefresh: () => _refresh(ref),
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
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: joinedAsync.when(
                      loading: () => Column(
                        children: List.generate(
                          4,
                          (i) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: SkeletonBox(height: 64, borderRadius: 16),
                          ),
                        ),
                      ),
                      error: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Couldn\'t load your tournaments',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      data: (tournaments) {
                        if (tournaments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'You haven\'t joined any tournaments yet',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
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
                                    onTap: () => _openTournament(context, t.id),
                                    child: UpcomingTournamentRow(
                                      tournament: t,
                                      game: games[t.gameId],
                                      onJoinTap: () =>
                                          _openTournament(context, t.id),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 1) return;
          if (i == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          }
          if (i == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
            return;
          }
          if (i == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            return;
          }
        },
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
          'My Tournaments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tournaments you\'ve joined',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}