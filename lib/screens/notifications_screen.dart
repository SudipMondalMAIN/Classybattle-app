import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_exception.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton.dart';
import 'settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();

  bool _loading = true;
  String? _error;
  List<AppNotification> _items = [];
  int _tab = 0; // 0 = All, 1 = Unread

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _notificationService.list(page: 1, pageSize: 30);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong: $e';
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _notificationService.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items.map((n) => n).toList();
      });
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _handleTap(AppNotification item) async {
    if (!item.isRead) {
      try {
        await _notificationService.markRead(item.id);
        if (!mounted) return;
        setState(() {
          final idx = _items.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            _items[idx] = AppNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              eventType: item.eventType,
              isRead: true,
              createdAt: item.createdAt,
            );
          }
        });
      } on ApiException {
        // Non-fatal — leave item as unread if the request failed.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Notifications',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: const Icon(Icons.settings_rounded, color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _tabButton('All', 0),
                  const SizedBox(width: 20),
                  _tabButton('Unread', 1),
                  const Spacer(),
                  GestureDetector(
                    onTap: _markAllRead,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.purple, size: 16),
                        SizedBox(width: 4),
                        Text('Mark all as read',
                            style: TextStyle(color: AppColors.purple, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: selected ? AppColors.purple : AppColors.textSecondary,
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
          const SizedBox(height: 5),
          Container(height: 2, width: 22, color: selected ? AppColors.purple : Colors.transparent),
        ],
      ),
    );
  }

  List<AppNotification> get _filteredItems =>
      _tab == 1 ? _items.where((n) => !n.isRead).toList() : _items;

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: 6,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonCircle(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: SkeletonBox(height: 13)),
                        const SizedBox(width: 8),
                        SkeletonBox(width: 40, height: 10),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const SkeletonBox(height: 10),
                    const SizedBox(height: 6),
                    SkeletonBox(width: 160, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 40, 18, 20),
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      );
    }
    final items = _filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Text(_tab == 1 ? 'No unread notifications' : 'No notifications yet',
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: items.length,
        itemBuilder: (context, i) => _NotifTile(
          item: items[i],
          onTap: () => _handleTap(items[i]),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback? onTap;
  const _NotifTile({required this.item, this.onTap});

  IconData get _icon {
    switch (item.eventType) {
      case 'wallet_credited':
      case 'wallet_debited':
      case 'refund_completed':
        return Icons.account_balance_wallet_rounded;
      case 'registration_successful':
        return Icons.check_circle_rounded;
      case 'registration_cancelled':
      case 'tournament_cancelled':
        return Icons.cancel_rounded;
      case 'tournament_created':
      case 'tournament_updated':
        return Icons.emoji_events_rounded;
      case 'match_created':
      case 'match_started':
      case 'live_match_started':
        return Icons.card_giftcard_rounded;
      case 'match_completed':
      case 'match_result_approved':
        return Icons.flag_circle_rounded;
      case 'room_details_published':
        return Icons.meeting_room_rounded;
      case 'winner_declared':
      case 'prize_distributed':
        return Icons.star_rounded;
      case 'admin_broadcast':
      case 'system_announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (item.eventType) {
      case 'wallet_credited':
      case 'refund_completed':
        return AppColors.purple;
      case 'wallet_debited':
        return AppColors.danger;
      case 'registration_successful':
        return AppColors.success;
      case 'registration_cancelled':
      case 'tournament_cancelled':
        return AppColors.danger;
      case 'tournament_created':
      case 'tournament_updated':
        return AppColors.purple;
      case 'match_created':
      case 'match_started':
      case 'live_match_started':
        return AppColors.blue;
      case 'winner_declared':
      case 'prize_distributed':
        return AppColors.success;
      case 'admin_broadcast':
      case 'system_announcement':
        return AppColors.warning;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: item.isRead ? AppColors.cardBorder : AppColors.purple.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      Text(DateFormat('d MMM, h:mm a').format(item.createdAt.toLocal()),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: 6),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}
