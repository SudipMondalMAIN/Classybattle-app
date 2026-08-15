import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/live_tournament_card.dart';
import '../widgets/home/section_header.dart';
import '../widgets/home/upcoming_tournament_row.dart';
import '../widgets/tournaments/search_filter_bar.dart';
import '../widgets/tournaments/tournament_filtered_list.dart';
import '../widgets/tournaments/tournament_tabs.dart';
import '../widgets/tournaments/your_tournaments_section.dart';
import 'create_custom_tournament_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tournament_details_screen.dart';
import 'wallet_screen.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key, this.initialGameId, this.initialCategory});

  /// Pre-applied game/category filter when arriving from a home-screen
  /// category box (e.g. "Free Fire Solo") -- null means no filter, the
  /// normal entry point from the bottom nav.
  final String? initialGameId;
  final String? initialCategory;

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialGameId != null || widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialGameId != null) {
          ref.read(tournamentGameFilterProvider.notifier).state =
              widget.initialGameId;
        }
        if (widget.initialCategory != null) {
          ref.read(tournamentCategoryFilterProvider.notifier).state =
              widget.initialCategory;
        }
      });
    }
  }

  @override
  void dispose() {
    // Don't leak a category-box filter into the next time Tournaments is
    // opened normally (e.g. from the bottom nav).
    ref.read(tournamentGameFilterProvider.notifier).state = null;
    ref.read(tournamentCategoryFilterProvider.notifier).state = null;
    super.dispose();
  }

  void _openTournament(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentDetailsScreen(tournamentId: id),
      ),
    );
  }

  void _openCreateCustomTournament() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCustomTournamentScreen()),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(allTournamentsProvider);
    ref.invalidate(liveTournamentsCountProvider);
    ref.invalidate(tournamentsForSelectedTabProvider);
    ref.invalidate(myTournamentStatsProvider);
    ref.invalidate(gamesByIdProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(currentUserProvider);
    // Wait for the real re-fetches instead of a fixed delay -- these
    // calls can take a few seconds, so a short fake delay made the
    // spinner vanish before fresh data actually arrived (looked like
    // refresh wasn't doing anything).
    await Future.wait([
      ref.read(allTournamentsProvider.future),
      ref.read(liveTournamentsCountProvider.future),
      ref.read(tournamentsForSelectedTabProvider.future),
      ref.read(myTournamentStatsProvider.future),
      ref.read(gamesByIdProvider.future),
      ref.read(walletProvider.future),
      ref.read(currentUserProvider.future),
    ].map((f) => f.catchError((_) => null)));
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTournamentTabProvider);

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
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: SearchFilterBar()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                const SliverToBoxAdapter(child: TournamentTabsBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                if (tab == TournamentTab.all) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Live Tournaments',
                        onViewAll: () =>
                            ref
                                .read(selectedTournamentTabProvider.notifier)
                                .state = TournamentTab
                                .live,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(child: _LiveRow(onTap: _openTournament)),
                  const SliverToBoxAdapter(child: SizedBox(height: 26)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Upcoming Tournaments',
                        onViewAll: () =>
                            ref
                                .read(selectedTournamentTabProvider.notifier)
                                .state = TournamentTab
                                .upcoming,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _UpcomingList(onTap: _openTournament),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: YourTournamentsSection(
                        onViewAll: () =>
                            ref
                                .read(selectedTournamentTabProvider.notifier)
                                .state = TournamentTab
                                .mine,
                      ),
                    ),
                  ),
                ] else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: TournamentFilteredList(
                        onOpenTournament: _openTournament,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: widget.initialCategory == 'custom'
          ? FloatingActionButton.extended(
              onPressed: _openCreateCustomTournament,
              backgroundColor: AppColors.purple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Host One',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
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
          'Tournaments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Compete. Conquer. Win.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _LiveRow extends ConsumerWidget {
  const _LiveRow({required this.onTap});
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allTournamentsProvider);
    final gamesAsync = ref.watch(gamesByIdProvider);

    return allAsync.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purpleSoft),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Couldn\'t load live tournaments',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
      data: (all) {
        final live = all.where((t) => t.isLive).toList();
        if (live.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text(
              'No live tournaments right now',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          );
        }
        final games = gamesAsync.valueOrNull ?? const {};
        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: live.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = live[i];
              return GestureDetector(
                onTap: () => onTap(t.id),
                child: LiveTournamentCard(tournament: t, game: games[t.gameId]),
              );
            },
          ),
        );
      },
    );
  }
}

class _UpcomingList extends ConsumerWidget {
  const _UpcomingList({required this.onTap});
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allTournamentsProvider);
    final gamesAsync = ref.watch(gamesByIdProvider);

    return allAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purpleSoft),
        ),
      ),
      error: (_, __) => const Text(
        'Couldn\'t load upcoming tournaments',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
      data: (all) {
        final upcoming = all
            .where((t) => t.status == 'scheduled')
            .take(3)
            .toList();
        if (upcoming.isEmpty) {
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
          children: upcoming
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onTap(t.id),
                    child: UpcomingTournamentRow(
                      tournament: t,
                      game: games[t.gameId],
                      onJoinTap: () => onTap(t.id),
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
