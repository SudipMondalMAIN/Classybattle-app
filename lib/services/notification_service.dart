import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String eventType;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.eventType,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      eventType: json['event_type'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Wraps app/api/v1/notification_routes.py.
class NotificationService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<AppNotification>> list({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _dio.get('/notifications', queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final items = res.data['items'] as List;
      return items.map((e) => AppNotification.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get('/notifications/unread-count');
      return res.data['unread_count'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Registers this device's FCM token with the backend so it can receive
  /// push notifications (see DeviceTokenRegisterRequest in notification_routes.py).
  Future<void> registerDeviceToken(String fcmToken, {String platform = 'android'}) async {
    try {
      await _dio.post('/notifications/device-tokens', data: {
        'fcm_token': fcmToken,
        'platform': platform,
      });
    } on DioException catch (e) {
      // Non-fatal — app should still work without push.
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deregisterDeviceToken(String fcmToken) async {
    try {
      await _dio.delete('/notifications/device-tokens', data: {'fcm_token': fcmToken});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
