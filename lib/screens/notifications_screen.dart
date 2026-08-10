import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_exception.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: _markAllRead,
                    child: const Icon(Icons.done_all_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
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
    if (_items.isEmpty) {
      return const Center(
        child: Text('No notifications yet', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: _items.length,
        itemBuilder: (context, i) => _NotifTile(
          item: _items[i],
          onTap: () => _handleTap(_items[i]),
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
      case 'wallet_credit':
      case 'wallet_debit':
      case 'deposit_approved':
      case 'deposit_rejected':
        return Icons.account_balance_wallet_rounded;
      case 'tournament_registration':
      case 'tournament_update':
      case 'match_live':
        return Icons.emoji_events_rounded;
      case 'prize_credited':
        return Icons.card_giftcard_rounded;
      case 'friend_request':
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (item.eventType) {
      case 'wallet_credit':
      case 'prize_credited':
      case 'deposit_approved':
        return AppColors.success;
      case 'wallet_debit':
      case 'deposit_rejected':
        return AppColors.danger;
      case 'tournament_registration':
      case 'tournament_update':
      case 'match_live':
        return AppColors.purple;
      default:
        return AppColors.blue;
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
                color: _color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
