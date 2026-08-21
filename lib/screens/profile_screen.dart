import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../providers/home_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/profile/account_section.dart';
import '../widgets/profile/profile_card.dart';
import '../widgets/profile/profile_header_bar.dart';
import '../widgets/profile/profile_stats_card.dart';
import '../widgets/profile/profile_tournament_card.dart';
import '../widgets/profile/profile_tournament_tabs.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'game_profiles_screen.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'support_chat_screen.dart';
import 'tournament_details_screen.dart';
import 'tournaments_screen.dart';
import 'transactions_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _notImplemented(String what) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$what — coming soon')));
  }

  Future<void> _refresh() async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(myTournamentStatsProvider);
    ref.invalidate(myTournamentEntriesProvider);
    ref.invalidate(gamesByIdProvider);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

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
            child: userAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              ),
              error: (_, __) => _ErrorState(onRetry: _refresh),
              data: (user) {
                if (user == null) {
                  return _LoggedOutState(onRefresh: _refresh);
                }
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ProfileHeaderBar(
                        onNotificationsTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        onSettingsTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: ProfileCard(
                          user: user,
                          onEditProfile: () async {
                            final changed = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(user: user),
                              ),
                            );
                            if (changed == true) {
                              ref.invalidate(currentUserProvider);
                            }
                          },
                          onChangeAvatar: () async {
                            final changed = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(user: user),
                              ),
                            );
                            if (changed == true) {
                              ref.invalidate(currentUserProvider);
                            }
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final statsAsync = ref.watch(
                              myTournamentStatsProvider,
                            );
                            final winRateAsync = ref.watch(winRateProvider);
                            final stats = statsAsync.valueOrNull;
                            return ProfileStatsCard(
                              joined: stats?.joined ?? 0,
                              won: stats?.won ?? 0,
                              totalWinnings: stats?.totalWinnings ?? 0,
                              winRate: winRateAsync.valueOrNull,
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'My Tournaments',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(
                                      selectedTournamentTabProvider.notifier,
                                    )
                                    .state = TournamentTab
                                    .mine;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TournamentsScreen(),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View All',
                                    style: TextStyle(
                                      color: AppColors.purpleSoft,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: AppColors.purpleSoft,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final tab = ref.watch(profileTournamentTabProvider);
                            return ProfileTournamentTabs(
                              selected: tab,
                              onSelect: (t) =>
                                  ref
                                          .read(
                                            profileTournamentTabProvider
                                                .notifier,
                                          )
                                          .state =
                                      t,
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final entriesAsync = ref.watch(
                            myTournamentsForTabProvider,
                          );
                          final gamesAsync = ref.watch(gamesByIdProvider);
                          return entriesAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                            error: (_, __) => const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              child: Text(
                                'Could not load your tournaments.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                            data: (entries) {
                              if (entries.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'Nothing here yet.',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final games = gamesAsync.valueOrNull ?? const {};
                              // Horizontal swipe instead of a long vertical
                              // scroll — one card-width peek of the next
                              // card signals there's more to swipe to.
                              return SizedBox(
                                height: 96,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: entries.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final e = entries[i];
                                    return SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          64,
                                      child: ProfileTournamentCard(
                                        tournament: e.tournament,
                                        game: games[e.tournament.gameId],
                                        participantStatus: e.participantStatus,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TournamentDetailsScreen(
                                                  tournamentId: e.tournament.id,
                                                ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Consumer(
                              builder: (context, ref, _) {
                                final wallet = ref.watch(walletProvider);
                                return AccountSectionCard(
                                  rows: [
                                    AccountRow(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      label: 'Wallet',
                                      trailingText: wallet.valueOrNull != null
                                          ? formatRupees(
                                              wallet
                                                  .valueOrNull!
                                                  .availableBalance,
                                            )
                                          : null,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const WalletScreen(),
                                        ),
                                      ),
                                    ),
                                    AccountRow(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Edit Profile',
                                      onTap: () async {
                                        final changed =
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditProfileScreen(
                                                      user: user,
                                                    ),
                                              ),
                                            );
                                        if (changed == true) {
                                          ref.invalidate(currentUserProvider);
                                        }
                                      },
                                    ),
                                    AccountRow(
                                      icon: Icons.leaderboard_rounded,
                                      label: 'Leaderboard',
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const LeaderboardScreen(),
                                        ),
                                      ),
                                    ),
                                    AccountRow(
                                      icon: Icons.sports_esports_rounded,
                                      label: 'Game Profiles',
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const GameProfilesScreen(),
                                        ),
                                      ),
                                    ),
                                    AccountRow(
                                      icon: Icons.shield_outlined,
                                      label: 'Security',
                                      trailingText: 'Change Password',
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SettingsScreen(),
                                        ),
                                      ),
                                    ),
                                    AccountRow(
                                      icon: Icons.history_rounded,
                                      label: 'Transaction History',
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TransactionsScreen(),
                                        ),
                                      ),
                                    ),
                                    AccountRow(
                                      icon: Icons.diversity_3_rounded,
                                      label: 'Refer & Earn',
                                      trailingBadge: 'Earn Rewards',
                                      onTap: () =>
                                          _notImplemented('Refer & Earn'),
                                    ),
                                    AccountRow(
                                      icon: Icons.headset_mic_outlined,
                                      label: 'Help & Support',
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SupportChatScreen(),
                                        ),
                                      ),
                                    ),
                                    AccountRow(
                                      icon: Icons.info_outline_rounded,
                                      label: 'About ClassyBattle',
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SettingsScreen(),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
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
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          if (i == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TournamentsScreen()),
            );
          } else if (i == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
          }
        },
      ),
    );
  }
}

class _LoggedOutState extends ConsumerWidget {
  const _LoggedOutState({required this.onRefresh});
  final Future<void> Function() onRefresh;

  Future<void> _login(BuildContext context, WidgetRef ref) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    // Refresh whether or not login succeeded -- cheap no-op if it didn't.
    ref.invalidate(currentUserProvider);
    ref.invalidate(walletProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Log in to view your profile',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _login(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Could not load your profile.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: AppColors.purpleSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
