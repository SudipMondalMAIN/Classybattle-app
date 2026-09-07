import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../models/tournament_model.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/common/skeleton.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/upcoming_tournament_row.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tournament_details_screen.dart';
import 'wallet_screen.dart';

/// Status filter for the My Tournaments screen. Mirrors the backend's
/// tournament.status values directly (see TournamentModel.status) plus
/// an "all" option -- this is a client-only filter over the already
/// -fetched joined-tournaments list, not a separate API call.
enum MyTournamentsStatusFilter { all, upcoming, live, completed, cancelled }

extension MyTournamentsStatusFilterX on MyTournamentsStatusFilter {
  String get label => switch (this) {
    MyTournamentsStatusFilter.all => 'All',
    MyTournamentsStatusFilter.upcoming => 'Upcoming',
    MyTournamentsStatusFilter.live => 'Live',
    MyTournamentsStatusFilter.completed => 'Completed',
    MyTournamentsStatusFilter.cancelled => 'Cancelled',
  };

  /// Matches TournamentModel.status ('scheduled' | 'live' | 'completed'
  /// | 'cancelled'). "Upcoming" maps to the backend's 'scheduled'.
  bool matches(String status) => switch (this) {
    MyTournamentsStatusFilter.all => true,
    MyTournamentsStatusFilter.upcoming => status == 'scheduled',
    MyTournamentsStatusFilter.live => status == 'live',
    MyTournamentsStatusFilter.completed => status == 'completed',
    MyTournamentsStatusFilter.cancelled => status == 'cancelled',
  };
}

final myTournamentsStatusFilterProvider =
    StateProvider<MyTournamentsStatusFilter>(
  (ref) => MyTournamentsStatusFilter.all,
);

/// Selected game id to filter by, or null for "All Games". Options are
/// built from whatever games actually appear in the joined list, so
/// this naturally covers every game/mode variant (CS 1v1, CS Headshot
/// Solo, Duo, etc.) without hardcoding names.
final myTournamentsGameFilterProvider = StateProvider<String?>((ref) => null);

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
    final statusFilter = ref.watch(myTournamentsStatusFilterProvider);
    final gameFilter = ref.watch(myTournamentsGameFilterProvider);

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
                SliverToBoxAdapter(
                  child: joinedAsync.maybeWhen(
                    data: (tournaments) => tournaments.isEmpty
                        ? const SizedBox.shrink()
                        : _FiltersBlock(
                            tournaments: tournaments,
                            games: gamesAsync.valueOrNull ?? const {},
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
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
                        final filtered = tournaments.where((t) {
                          if (!statusFilter.matches(t.status)) return false;
                          if (gameFilter != null && t.gameId != gameFilter) {
                            return false;
                          }
                          return true;
                        }).toList();
                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No tournaments match these filters',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: filtered
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

class _FiltersBlock extends ConsumerWidget {
  const _FiltersBlock({required this.tournaments, required this.games});

  final List<TournamentModel> tournaments;
  final Map<String, GameModel> games;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(myTournamentsStatusFilterProvider);
    final gameFilter = ref.watch(myTournamentsGameFilterProvider);

    // Only offer game chips for games the user has actually joined
    // tournaments in -- covers every game/mode variant (CS 1v1, CS
    // Headshot Solo, Duo, etc.) automatically instead of hardcoding.
    final seenGameIds = <String>{};
    final gameOptions = <MapEntry<String, String>>[]; // gameId -> name
    for (final t in tournaments) {
      if (seenGameIds.add(t.gameId)) {
        final name = games[t.gameId]?.name ?? 'Unknown';
        gameOptions.add(MapEntry(t.gameId, name));
      }
    }
    gameOptions.sort((a, b) => a.value.compareTo(b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final f in MyTournamentsStatusFilter.values) ...[
                _FilterChip(
                  label: f.label,
                  active: f == statusFilter,
                  onTap: () => ref
                      .read(myTournamentsStatusFilterProvider.notifier)
                      .state = f,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (gameOptions.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'All Games',
                  active: gameFilter == null,
                  onTap: () => ref
                      .read(myTournamentsGameFilterProvider.notifier)
                      .state = null,
                ),
                const SizedBox(width: 8),
                for (final g in gameOptions) ...[
                  _FilterChip(
                    label: g.value,
                    active: g.key == gameFilter,
                    onTap: () => ref
                        .read(myTournamentsGameFilterProvider.notifier)
                        .state = g.key,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: active
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: AppColors.purpleButton,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : GlassContainer(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
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