import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/upcoming_tournament_row.dart';
import 'create_custom_tournament_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tournament_details_screen.dart';
import 'wallet_screen.dart';

/// Dedicated browse page for user-hosted Custom Tournaments (join via
/// room_id, squad-based -- no solo/squad sub-filter). This is separate
/// from the main Tournaments screen/tabs; tapping a tournament here
/// opens the same TournamentDetailsScreen used everywhere else.
class CustomTournamentsScreen extends ConsumerStatefulWidget {
  const CustomTournamentsScreen({super.key});

  @override
  ConsumerState<CustomTournamentsScreen> createState() =>
      _CustomTournamentsScreenState();
}

class _CustomTournamentsScreenState
    extends ConsumerState<CustomTournamentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(customTournamentsProvider);
    ref.invalidate(gamesByIdProvider);
    await Future.wait(
      [
        ref.read(customTournamentsProvider.future),
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

  void _openCreateCustomTournament() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCustomTournamentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customAsync = ref.watch(customTournamentsProvider);
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
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search custom tournaments...',
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (v) => setState(
                                () => _query = v.trim().toLowerCase(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: customAsync.when(
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
                    error: (_, __) => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Couldn\'t load custom tournaments',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    data: (tournaments) {
                      final filtered = _query.isEmpty
                          ? tournaments
                          : tournaments
                                .where(
                                  (t) => t.title.toLowerCase().contains(_query),
                                )
                                .toList();
                      if (filtered.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                tournaments.isEmpty
                                    ? 'No custom tournaments yet'
                                    : 'No matches found',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCustomTournament,
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Tournament',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
          'Custom Tournaments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'User-hosted. Join with a room ID.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}
