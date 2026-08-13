import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around secure storage for auth tokens + the cached user id,
/// used across the app (login/signup screens, API client interceptor).
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'cb_access_token';
  static const _refreshTokenKey = 'cb_refresh_token';

  static Future<String?> readAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
