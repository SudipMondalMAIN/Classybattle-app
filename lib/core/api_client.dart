import 'package:dio/dio.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Called by ApiClient when the refresh token itself is rejected
/// (session fully expired) — the app should log the user out.
typedef OnSessionExpired = void Function();

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // /auth/* endpoints don't need a bearer token.
          if (!options.path.startsWith('/auth/')) {
            final token = await TokenStorage.instance.accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !isAuthEndpoint && !alreadyRetried) {
            final refreshed = await _tryRefreshToken();
            if (refreshed != null) {
              final req = error.requestOptions;
              req.headers['Authorization'] = 'Bearer $refreshed';
              req.extra['retried'] = true;
              try {
                final response = await _dio.fetch(req);
                return handler.resolve(response);
              } catch (_) {
                // fall through to propagate original error
              }
            } else {
              await TokenStorage.instance.clear();
              onSessionExpired?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  Dio get dio => _dio;

  /// Set by the app root once, so 401-on-refresh can trigger a logout/navigation.
  OnSessionExpired? onSessionExpired;

  Future<String?> _tryRefreshToken() async {
    final refreshToken = await TokenStorage.instance.refreshToken;
    if (refreshToken == null) return null;
    try {
      // Bare Dio call (not _dio) to avoid re-triggering the auth interceptor.
      final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
        '/auth/token/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccess = response.data['access_token'] as String;
      await TokenStorage.instance.saveAccessToken(newAccess);
      return newAccess;
    } catch (_) {
      return null;
    }
  }
}
