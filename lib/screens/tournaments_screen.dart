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
import 'tournament_details_screen.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen> {
  void _openTournament(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournamentId: id)),
    );
  }

  void _notImplemented(String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what — coming soon')));
  }

  Future<void> _refresh() async {
    ref.invalidate(allTournamentsProvider);
    ref.invalidate(liveTournamentsCountProvider);
    ref.invalidate(tournamentsForSelectedTabProvider);
    ref.invalidate(myTournamentStatsProvider);
    ref.invalidate(gamesByIdProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(currentUserProvider);
    await Future.delayed(const Duration(milliseconds: 300));
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
                    onNotificationsTap: () => _notImplemented('Notifications'),
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
                        onViewAll: () => ref
                            .read(selectedTournamentTabProvider.notifier)
                            .state = TournamentTab.live,
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
                        onViewAll: () => ref
                            .read(selectedTournamentTabProvider.notifier)
                            .state = TournamentTab.upcoming,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(child: _UpcomingList(onTap: _openTournament)),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: YourTournamentsSection(
                        onViewAll: () => ref
                            .read(selectedTournamentTabProvider.notifier)
                            .state = TournamentTab.mine,
                      ),
                    ),
                  ),
                ] else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: TournamentFilteredList(onOpenTournament: _openTournament),
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
          Navigator.of(context).pop();
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
        child: Center(child: CircularProgressIndicator(color: AppColors.purpleSoft)),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Couldn\'t load live tournaments',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ),
      data: (all) {
        final live = all.where((t) => t.isLive).toList();
        if (live.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text('No live tournaments right now',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                child: LiveTournamentCard(
                  tournament: t,
                  game: games[t.gameId],
                  onJoinTap: () => onTap(t.id),
                ),
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
        child: Center(child: CircularProgressIndicator(color: AppColors.purpleSoft)),
      ),
      error: (_, __) => const Text('Couldn\'t load upcoming tournaments',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      data: (all) {
        final upcoming = all.where((t) => t.status == 'scheduled').take(3).toList();
        if (upcoming.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No upcoming tournaments yet',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
