import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/notification_service.dart';

enum NotificationTab { all, unread }

final notificationTabProvider =
    StateProvider<NotificationTab>((ref) => NotificationTab.all);

/// Real unread count, used for badges elsewhere in the app (e.g. a future
/// bell icon). Kept independent from the list so it can refresh cheaply.
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  try {
    return await notificationService.fetchUnreadCount();
  } on UnauthenticatedException {
    return 0;
  }
});

/// Loads + owns the in-memory notification list for the Notifications
/// Screen. A single source fetched with is_read=null (server default is
/// "all"); the Unread tab filters this list client-side so switching tabs
/// doesn't require a re-fetch, while mark-as-read/mark-all-as-read still
/// hit the real backend endpoints and update this state immediately.
class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  static const _pageSize = 20;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  @override
  Future<List<NotificationModel>> build() async {
    _page = 1;
    _hasMore = true;
    try {
      final result = await notificationService.fetchNotifications(
        page: 1,
        pageSize: _pageSize,
      );
      _hasMore = _page < result.totalPages;
      return result.items;
    } on UnauthenticatedException {
      _hasMore = false;
      return [];
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;
    _loadingMore = true;
    try {
      final next = _page + 1;
      final result = await notificationService.fetchNotifications(
        page: next,
        pageSize: _pageSize,
      );
      _page = next;
      _hasMore = _page < result.totalPages;
      state = AsyncData([...current, ...result.items]);
    } on UnauthenticatedException {
      _hasMore = false;
    } finally {
      _loadingMore = false;
    }
  }

  /// Re-fetches page 1 WITHOUT clearing the currently shown list first.
  /// The old data stays on screen the whole time; it's only swapped once
  /// the new data has actually arrived. This is what makes "silent"
  /// auto-refresh (e.g. on push notification) invisible to the user —
  /// no spinner flash, no empty-list flicker.
  Future<void> refresh({bool silent = true}) async {
    if (!silent) {
      state = const AsyncLoading();
    }
    final previous = state;
    final next = await AsyncValue.guard(() => build());
    // AsyncValue.guard already carries the new data/error; attach the
    // previous value as "previous" so consumers that check
    // `hasValue`/`valueOrNull` keep seeing something during the brief
    // await above, then flip to the fresh result.
    state = next.hasError ? next.copyWithPrevious(previous) : next;
  }

  /// Marks one notification read, both on the backend and in local state
  /// (so the unread dot disappears immediately without waiting on a
  /// re-fetch).
  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final target = current.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) return;

    state = AsyncData([
      for (final n in current)
        if (n.id == id) n.copyWith(isRead: true, readAt: DateTime.now()) else n,
    ]);
    try {
      await notificationService.markRead(id);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      // Best-effort: leave optimistic local state even if the network
      // call fails silently; next refresh will reconcile.
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final n in current)
        n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now()),
    ]);
    try {
      await notificationService.markAllRead();
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {}
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
