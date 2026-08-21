import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../providers/wallet_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/wallet/recent_transactions_section.dart';
import '../widgets/wallet/wallet_balance_card.dart';
import '../widgets/wallet/wallet_header_bar.dart';
import 'add_money_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';
import 'tournaments_screen.dart';
import 'withdraw_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  Future<void> _refresh() async {
    ref.invalidate(walletProvider);
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  void _openViewAll() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
    );
  }

  void _openAddMoney() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
    ).then((_) => _refresh());
  }

  void _openWithdraw() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WithdrawScreen()),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGradientTop, AppColors.backgroundGradientBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              WalletHeaderBar(
                onNotificationsTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              const SizedBox(height: 14),
              // Locked in place: stays fixed on screen while only the
              // content below (summary/transactions) scrolls.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WalletBalanceCard(
                  wallet: walletAsync.valueOrNull,
                  onAddMoney: _openAddMoney,
                  onWithdraw: _openWithdraw,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecentTransactionsHeader(onViewAll: _openViewAll),
                      const SizedBox(height: 4),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.purple,
                          backgroundColor: AppColors.background,
                          onRefresh: _refresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 110),
                            children: [
                              RecentTransactionsList(
                                async: recentAsync,
                                onRetry: () => ref.invalidate(recentTransactionsProvider),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          if (i == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TournamentsScreen()),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}
