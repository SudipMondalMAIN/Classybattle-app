import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../providers/notification_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/notifications/notification_card.dart';
import '../widgets/notifications/notification_router.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'tournaments_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _onTapNotification(NotificationModel n) async {
    if (!n.isRead) {
      await ref.read(notificationsProvider.notifier).markRead(n.id);
    }
    if (!mounted) return;
    navigateForNotification(context, n);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(notificationTabProvider);
    final async = ref.watch(notificationsProvider);

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
          child: Column(
            children: [
              _Header(),
              _Tabs(tab: tab),
              Expanded(
                child: async.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  ),
                  error: (err, _) => _ErrorState(
                    onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
                  ),
                  data: (items) {
                    final filtered = tab == NotificationTab.unread
                        ? items.where((n) => !n.isRead).toList()
                        : items;
                    if (filtered.isEmpty) {
                      return _EmptyState(unreadTab: tab == NotificationTab.unread);
                    }
                    final notifier = ref.read(notificationsProvider.notifier);
                    return RefreshIndicator(
                      color: AppColors.purple,
                      backgroundColor: const Color(0xFF14101F),
                      onRefresh: notifier.refresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filtered.length + (notifier.loadingMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= filtered.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                            );
                          }
                          final n = filtered[i];
                          return NotificationCard(
                            notification: n,
                            onTap: () => _onTapNotification(n),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(context: context),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends ConsumerWidget {
  const _Tabs({required this.tab});
  final NotificationTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final hasUnread = async.valueOrNull?.any((n) => !n.isRead) ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
      child: Row(
        children: [
          _TabItem(
            label: 'All',
            selected: tab == NotificationTab.all,
            onTap: () => ref.read(notificationTabProvider.notifier).state =
                NotificationTab.all,
          ),
          const SizedBox(width: 22),
          _TabItem(
            label: 'Unread',
            selected: tab == NotificationTab.unread,
            onTap: () => ref.read(notificationTabProvider.notifier).state =
                NotificationTab.unread,
          ),
          const Spacer(),
          if (hasUnread)
            GestureDetector(
              onTap: () => ref.read(notificationsProvider.notifier).markAllRead(),
              behavior: HitTestBehavior.opaque,
              child: const Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 16, color: AppColors.purple),
                  SizedBox(width: 4),
                  Text(
                    'Mark all as read',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.purple : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 2.5,
            width: selected ? 26 : 0,
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.unreadTab});
  final bool unreadTab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                unreadTab
                    ? Icons.mark_email_read_rounded
                    : Icons.notifications_none_rounded,
                color: AppColors.textMuted,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              unreadTab ? "You're all caught up" : 'No notifications yet',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unreadTab
                  ? 'No unread notifications right now.'
                  : "We'll let you know when something happens.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.live, size: 36),
            const SizedBox(height: 12),
            const Text(
              "Couldn't load notifications",
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleButton,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: GlassContainer(
          borderRadius: 26,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          fillColor: Colors.black.withValues(alpha: 0.45),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                label: 'Home',
                active: false,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
              _NavIcon(
                icon: Icons.emoji_events_rounded,
                label: 'Tournaments',
                active: false,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TournamentsScreen()),
                ),
              ),
              _NavIcon(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Wallet',
                active: false,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                ),
              ),
              _NavIcon(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: true,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: active ? AppColors.purple : AppColors.textMuted),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.purple : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
