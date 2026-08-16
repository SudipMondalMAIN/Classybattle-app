import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/custom_tournament_box.dart';
import '../widgets/home/hero_banner_carousel.dart';
import '../widgets/home/home_category_boxes_section.dart';
import '../widgets/home/live_tournaments_section.dart';
import '../widgets/home/upcoming_tournaments_section.dart';
import 'custom_tournaments_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tournament_details_screen.dart';
import 'tournaments_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  Timer? _liveStatusTimer;

  @override
  void initState() {
    super.initState();
    // A tournament's live/completed status can flip in the background
    // (admin publishes a room, or the 40-min auto-complete tick fires)
    // with nobody touching the app -- without this, the hero banner and
    // live rail only ever refresh on pull-to-refresh, so they can keep
    // showing a tournament as "LIVE" long after it's actually completed,
    // or miss a tournament that just went live. Poll the
    // live-status-sensitive providers while the home screen is visible.
    _liveStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      ref.invalidate(liveTournamentsProvider);
      ref.invalidate(featuredLiveTournamentProvider);
      ref.invalidate(upcomingTournamentsProvider);
    });
  }

  @override
  void dispose() {
    _liveStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(bannersProvider);
    ref.invalidate(gamesByIdProvider);
    ref.invalidate(liveTournamentsProvider);
    ref.invalidate(upcomingTournamentsProvider);
    ref.invalidate(featuredLiveTournamentProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(currentUserProvider);
    // Give listeners a beat to kick off before the indicator dismisses.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _openTournaments() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentsScreen()),
    );
  }

  void _openTournamentDetails(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournamentId: id)),
    );
  }

  void _openWallet() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openTournamentsFiltered(String gameId, String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentsScreen(
          initialGameId: gameId,
          initialCategory: category,
        ),
      ),
    );
  }

  /// Both the "Custom" tile in the Solo/Squad/Custom grid and the
  /// standalone "host your own" banner above it open the same dedicated
  /// browse page (not the main Tournaments screen, and not straight to
  /// the creation form) -- lists tournaments other users have already
  /// hosted (join via room_id, squad-based -- no solo/squad sub-filter
  /// needed). Creating one's own is still one tap away via the "Host
  /// One" button on that page.
  void _openCustomTournaments() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomTournamentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HeaderBar(
                        onNotificationsTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        ),
                        onWalletTap: _openWallet,
                        onProfileTap: _openProfile,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: HeroBannerCarousel(
                          onJoinTap: (featured) {
                            if (featured == null) {
                              _openTournaments();
                            } else {
                              _openTournamentDetails(featured.id);
                            }
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: CustomTournamentBox(
                          onTap: _openCustomTournaments,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: HomeCategoryBoxesSection(
                        onSoloOrSquadTap: _openTournamentsFiltered,
                        onCustomTap: _openCustomTournaments,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: LiveTournamentsSection(
                        onViewAll: () => _openTournaments(),
                        onJoinTap: (id) => _openTournamentDetails(id),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: UpcomingTournamentsSection(
                          onViewAll: () => _openTournaments(),
                          onJoinTap: (id) => _openTournamentDetails(id),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == _navIndex) return;
          if (i == 1) {
            _openTournaments();
            return;
          }
          if (i == 2) {
            _openWallet();
            return;
          }
          if (i == 3) {
            _openProfile();
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }
}
