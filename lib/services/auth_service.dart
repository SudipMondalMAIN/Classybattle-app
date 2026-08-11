import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

/// Wraps app/api/v1/auth_routes.py. Each method throws [ApiException] on failure.
class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  /// Step 1 of signup — sends OTP to email. Returns the message from backend.
  Future<String> signupInit({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/signup', data: {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
      });
      return res.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Step 2 of signup — verify OTP, returns tokens + activated user.
  Future<AppUser> verifySignupOtp({required String email, required String otp}) async {
    try {
      final res = await _dio.post('/auth/signup/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      return _saveTokensAndReturnUser(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> resendOtp({required String email, required String purpose}) async {
    try {
      final res = await _dio.post('/auth/otp/resend', data: {
        'email': email,
        'purpose': purpose, // "signup_verification" | "password_reset"
      });
      return res.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AppUser> login({required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return _saveTokensAndReturnUser(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /users/me — refetches the current user (used by Profile screen so
  /// data is live even after an app restart / cached login).
  Future<AppUser> getMe() async {
    try {
      final res = await _dio.get('/users/me');
      return AppUser.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// PATCH /users/me
  Future<AppUser> updateProfile({String? fullName, String? avatarId, String? bio, String? country}) async {
    try {
      final res = await _dio.patch('/users/me', data: {
        if (fullName != null) 'full_name': fullName,
        if (avatarId != null) 'avatar_id': avatarId,
        if (bio != null) 'bio': bio,
        if (country != null) 'country': country,
      });
      return AppUser.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await TokenStorage.instance.refreshToken;
    try {
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      }
    } on DioException {
      // ignore network errors on logout — clear local session regardless
    } finally {
      await TokenStorage.instance.clear();
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final res = await _dio.post('/auth/password/forgot', data: {'email': email});
      return res.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> verifyResetOtp({required String email, required String otp}) async {
    try {
      final res = await _dio.post('/auth/password/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      return res.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post('/auth/password/reset', data: {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      });
      return res.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AppUser> _saveTokensAndReturnUser(Map<String, dynamic> data) async {
    await TokenStorage.instance.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
