import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/notification_preferences_model.dart';
import 'home_service.dart' show UnauthenticatedException;

/// Thrown when a change-password step fails for a known, user-facing
/// reason (wrong OTP, weak password, etc).
class SettingsActionException implements Exception {
  SettingsActionException(this.message);
  final String message;
}

class SettingsService {
  SettingsService(this._dio);

  final Dio _dio;

  /// GET /notifications/preferences
  Future<NotificationPreferencesModel> fetchNotificationPreferences() async {
    try {
      final res = await _dio.get('/notifications/preferences');
      return NotificationPreferencesModel.fromJson(
        res.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// PUT /notifications/preferences -- real, persisted toggle update.
  Future<NotificationPreferencesModel> updateNotificationPreferences({
    bool? inAppEnabled,
    bool? pushEnabled,
    bool? emailEnabled,
  }) async {
    try {
      final res = await _dio.put(
        '/notifications/preferences',
        data: {
          if (inAppEnabled != null) 'in_app_enabled': inAppEnabled,
          if (pushEnabled != null) 'push_enabled': pushEnabled,
          if (emailEnabled != null) 'email_enabled': emailEnabled,
        },
      );
      return NotificationPreferencesModel.fromJson(
        res.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /auth/password/forgot -- step 1 of the real change-password
  /// flow (the backend has no "change password while logged in"
  /// endpoint, only the OTP-based reset flow, so Settings reuses it).
  Future<void> requestPasswordResetOtp(String email) async {
    await _dio.post('/auth/password/forgot', data: {'email': email});
  }

  /// POST /auth/password/verify-otp
  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    try {
      await _dio.post(
        '/auth/password/verify-otp',
        data: {'email': email, 'otp': otp},
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw SettingsActionException(
        detail?.toString() ?? 'That code is invalid or has expired.',
      );
    }
  }

  /// POST /auth/password/reset
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/password/reset',
        data: {'email': email, 'otp': otp, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw SettingsActionException(
        detail?.toString() ?? 'Could not reset your password right now.',
      );
    }
  }

  /// Clears the locally stored session. The backend's /auth/logout
  /// route needs a refresh token, which this client build doesn't
  /// persist (no login screen ships in this app yet -- see
  /// TokenStorage), so a real, functional logout here means dropping
  /// the access token so every provider falls back to its existing
  /// "not logged in" state, same as everywhere else in the app.
  Future<void> logout() async {
    await TokenStorage.clear();
  }
}

final settingsService = SettingsService(ApiClient.instance.dio);
