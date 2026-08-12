import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/home/category_shortcuts.dart';
import '../widgets/home/header_bar.dart';
import '../widgets/home/hero_banner_carousel.dart';
import '../widgets/home/how_it_works.dart';
import '../widgets/home/live_tournaments_section.dart';
import '../widgets/home/upcoming_tournaments_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

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

  void _notImplemented(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon')),
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
                        onNotificationsTap: () =>
                            _notImplemented('Notifications'),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: HeroBannerCarousel(
                          onJoinTap: (featured) {
                            if (featured == null) {
                              _notImplemented('Join tournament');
                            } else {
                              _notImplemented('Join "${featured.title}"');
                            }
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: CategoryShortcuts(
                          onTap: (label) => _notImplemented(label),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: LiveTournamentsSection(
                        onViewAll: () => _notImplemented('Live tournaments list'),
                        onJoinTap: (id) => _notImplemented('Join tournament'),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: UpcomingTournamentsSection(
                          onViewAll: () =>
                              _notImplemented('Upcoming tournaments list'),
                          onJoinTap: (id) => _notImplemented('Join tournament'),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: const SliverToBoxAdapter(child: HowItWorks()),
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
          setState(() => _navIndex = i);
          if (i != 0) {
            const labels = ['Home', 'Tournaments', 'Wallet', 'Profile'];
            _notImplemented(labels[i]);
            // Reset back to Home since those screens don't exist yet --
            // avoids a nav bar stuck pointing at a blank tab.
            Future.microtask(() => setState(() => _navIndex = 0));
          }
        },
      ),
    );
  }
}
