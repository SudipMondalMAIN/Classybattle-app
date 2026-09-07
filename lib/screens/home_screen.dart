import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../models/app_version_check.dart';
import '../theme/app_theme.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/hero_banner_carousel.dart';
import '../widgets/home/home_category_boxes_section.dart';
import '../widgets/home/refer_earn_banner.dart';
import '../widgets/home/soft_update_dialog.dart';
import 'custom_tournaments_screen.dart';
import 'free_tournaments_screen.dart';
import 'solo_tournaments_screen.dart';
import 'duo_tournaments_screen.dart';
import 'squad_tournaments_screen.dart';
import 'cs_1v1_tournaments_screen.dart';
import 'cs_head_tournaments_screen.dart';
import 'cs_4v4_tournaments_screen.dart';
import 'lw_1v1_tournaments_screen.dart';
import 'lw_head_tournaments_screen.dart';
import 'br_survive_tournaments_screen.dart';
import 'my_tournaments_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'refer_earn_screen.dart';
import 'tournament_details_screen.dart';
import 'tournaments_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.versionInfo});

  /// Non-null only when the splash screen's version check found an
  /// optional update (update_available=true, force_update=false).
  /// force_update=true never reaches here -- that goes to
  /// ForceUpdateScreen instead, before Home is ever built.
  final AppVersionCheck? versionInfo;

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
      ref.invalidate(featuredLiveTournamentProvider);
    });

    final info = widget.versionInfo;
    if (info != null && info.updateAvailable && !info.forceUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showSoftUpdateDialog(context, info);
      });
    }
  }

  @override
  void dispose() {
    _liveStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(bannersProvider);
    ref.invalidate(gamesByIdProvider);
    ref.invalidate(featuredLiveTournamentProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(currentUserProvider);
    // Give listeners a beat to kick off before the indicator dismisses.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _openTournaments() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TournamentsScreen()));
  }

  /// Bottom nav's "My Tournaments" tap -- opens the dedicated screen
  /// that shows only tournaments the user has actually joined. No
  /// tabs, no search, no Live/Upcoming/All browse sections -- just
  /// the user's own list.
  void _openMyTournaments() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyTournamentsScreen()));
  }

  void _openTournamentDetails(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentDetailsScreen(tournamentId: id),
      ),
    );
  }

  void _openWallet() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _openReferEarn() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReferEarnScreen()));
  }

  /// Every non-Custom home-category box opens its own dedicated
  /// per-format browse page, same pattern as Custom Tournaments below.
  void _openFormatTournaments(String format) {
    final Widget screen = switch (format) {
      'free' => const FreeTournamentsScreen(),
      'solo' => const SoloTournamentsScreen(),
      'duo' => const DuoTournamentsScreen(),
      'squad' => const SquadTournamentsScreen(),
      'cs_1v1' => const Cs1v1TournamentsScreen(),
      'cs_head' => const CsHeadTournamentsScreen(),
      'cs_4v4' => const Cs4v4TournamentsScreen(),
      'lw_1v1' => const Lw1v1TournamentsScreen(),
      'lw_head' => const LwHeadTournamentsScreen(),
      'br_survive' => const BrSurviveTournamentsScreen(),
      _ => const TournamentsScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Both the "Custom" tile in the Solo/Squad/Custom grid and the
  /// standalone "host your own" banner above it open the same dedicated
  /// browse page (not the main Tournaments screen, and not straight to
  /// the creation form) -- lists tournaments other users have already
  /// hosted (join via room_id, squad-based -- no solo/squad sub-filter
  /// needed). Creating one's own is still one tap away via the "Host
  /// One" button on that page.
  void _openCustomTournaments() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CustomTournamentsScreen()));
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
                            builder: (_) => const NotificationsScreen(),
                          ),
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
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: HomeCategoryBoxesSection(
                        onFormatTap: _openFormatTournaments,
                        onCustomTap: _openCustomTournaments,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: ReferEarnBanner(onTap: _openReferEarn),
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
            _openMyTournaments();
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
