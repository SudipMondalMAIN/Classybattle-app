import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around secure storage for the auth access token.
/// Login/signup screens aren't in scope here yet -- this just gives
/// the Home Screen's API calls a single place to read whatever token
/// (if any) a future auth flow writes, and to fail gracefully when
/// there isn't one.
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'cb_access_token';

  static Future<String?> readAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
