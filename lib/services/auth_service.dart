import 'dart:async';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user_model.dart';
import 'push_notification_handler.dart';

/// Thrown for any auth-flow failure with a clean, backend-provided
/// message (see app/middleware/exception_handlers.py -> {"message": ...}),
/// falling back to a generic message if the backend is unreachable.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult(this.user, this.accessToken, this.refreshToken);
  final UserModel user;
  final String accessToken;
  final String refreshToken;
}

class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }

  /// POST /auth/signup — step 1: sends an OTP to the given email.
  Future<void> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/signup',
        data: {
          'full_name': fullName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(e, "Couldn't create your account. Please try again."),
      );
    }
  }

  /// POST /auth/signup/verify-otp — step 2: verifies OTP, returns tokens.
  Future<AuthResult> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/signup/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return _resultFromTokenResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_messageFrom(e, 'Invalid or expired OTP.'));
    }
  }

  /// POST /auth/otp/resend
  Future<void> resendOtp({
    required String email,
    required String purpose, // 'signup_verification' | 'password_reset'
  }) async {
    try {
      await _dio.post(
        '/auth/otp/resend',
        data: {'email': email, 'purpose': purpose},
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(e, "Couldn't resend OTP. Please try again."),
      );
    }
  }

  /// POST /auth/login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _resultFromTokenResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_messageFrom(e, 'Invalid email or password.'));
    }
  }

  /// POST /auth/password/forgot
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/password/forgot', data: {'email': email});
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(e, "Couldn't send the reset OTP. Please try again."),
      );
    }
  }

  /// POST /auth/password/verify-otp
  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _dio.post(
        '/auth/password/verify-otp',
        data: {'email': email, 'otp': otp},
      );
    } on DioException catch (e) {
      throw AuthException(_messageFrom(e, 'Invalid or expired OTP.'));
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
      throw AuthException(
        _messageFrom(e, "Couldn't reset your password. Please try again."),
      );
    }
  }

  /// POST /auth/logout — best-effort; local session is always cleared by
  /// the caller regardless of whether this succeeds.
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
    } catch (_) {}
  }

  AuthResult _resultFromTokenResponse(Map<String, dynamic> data) {
    return AuthResult(
      UserModel.fromJson(data['user'] as Map<String, dynamic>),
      data['access_token'] as String,
      data['refresh_token'] as String,
    );
  }

  Future<void> persistSession(AuthResult result) async {
    await TokenStorage.writeTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    // Now that we have a session, push the already-fetched FCM token
    // (cached at app startup in PushNotificationHandler.init) to the
    // backend so this device actually starts receiving pushes.
    // Best-effort -- never blocks/breaks login on a network hiccup.
    unawaited(PushNotificationHandler.instance.registerTokenIfNeeded());
  }
}

final authService = AuthService(ApiClient.instance.dio);
