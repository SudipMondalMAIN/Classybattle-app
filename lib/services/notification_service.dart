import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/notification_model.dart';
import 'home_service.dart' show UnauthenticatedException;

class PagedNotifications {
  const PagedNotifications(this.items, this.total, this.totalPages);
  final List<NotificationModel> items;
  final int total;
  final int totalPages;
}

class NotificationService {
  NotificationService(this._dio);

  final Dio _dio;

  /// GET /notifications -- paginated, real notifications for the current
  /// user. [isRead] filters server-side (used for the Unread tab).
  Future<PagedNotifications> fetchNotifications({
    int page = 1,
    int pageSize = 20,
    bool? isRead,
  }) async {
    try {
      final res = await _dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'sort_by': 'created_at',
          'sort_order': 'desc',
          if (isRead != null) 'is_read': isRead,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedNotifications(
        items,
        (data['total'] as num?)?.toInt() ?? items.length,
        (data['total_pages'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// GET /notifications/unread-count
  Future<int> fetchUnreadCount() async {
    try {
      final res = await _dio.get('/notifications/unread-count');
      return (res.data['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// PATCH /notifications/{id}/read
  Future<void> markRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// PATCH /notifications/read-all
  Future<int> markAllRead() async {
    try {
      final res = await _dio.patch('/notifications/read-all');
      return (res.data['marked'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /notifications/device-tokens -- registers this device's FCM
  /// token against the current (authenticated) user so the backend
  /// knows where to push. Must be called whenever we have a fresh
  /// token AND the user is logged in (see PushNotificationHandler).
  Future<void> registerDeviceToken(String fcmToken, {required String platform}) async {
    try {
      await _dio.post(
        '/notifications/device-tokens',
        data: {'fcm_token': fcmToken, 'platform': platform},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final notificationService = NotificationService(ApiClient.instance.dio);