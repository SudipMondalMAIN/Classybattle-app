import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Single shared Dio instance for the whole app. Attaches the bearer
/// token (when one exists) to every request; endpoints that don't
/// require auth simply ignore the header on the backend side.
///
/// Also transparently refreshes an expired access token: the backend
/// issues a 30-minute access token, so without this a user would get
/// silently "logged out" (401 -> UnauthenticatedException) every 30
/// minutes even though their session (refresh token) is still good
/// for up to a year. On any 401, this interceptor swaps in a fresh
/// access token via POST /auth/token/refresh and retries the original
/// request once -- the user never sees it happen. Only a genuinely
/// expired/revoked refresh token (or no session at all) results in a
/// real logout.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Accept': 'application/json'},
      ),
    );

    // Separate, interceptor-free client for the refresh call itself --
    // using _dio here would recurse back into this same interceptor.
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            debugPrint('[API] -> ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API] <- ${response.statusCode} ${response.requestOptions.uri}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              '[API] !! ${error.requestOptions.uri} -> '
              '${error.type} ${error.message}',
            );
          }

          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried =
              error.requestOptions.extra['retriedAfterRefresh'] == true;
          final isRefreshCall = error.requestOptions.path.contains(
            '/auth/token/refresh',
          );

          if (!isUnauthorized || alreadyRetried || isRefreshCall) {
            handler.next(error);
            return;
          }

          final newAccessToken = await _refreshAccessToken();
          if (newAccessToken == null) {
            // Refresh token missing/expired/revoked -- this is a real
            // logout, let the 401 propagate as before.
            handler.next(error);
            return;
          }

          try {
            final retryOptions = error.requestOptions
              ..headers['Authorization'] = 'Bearer $newAccessToken'
              ..extra['retriedAfterRefresh'] = true;
            final response = await _dio.fetch(retryOptions);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  late final Dio _refreshDio;

  // Dedupes concurrent 401s (e.g. several widgets fetching at once)
  // into a single in-flight refresh call instead of firing one per
  // failed request.
  Future<String?>? _refreshInFlight;

  Future<String?> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await TokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _refreshDio.post(
        '/auth/token/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccessToken = response.data['access_token'] as String;
      await TokenStorage.writeAccessToken(newAccessToken);
      return newAccessToken;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[API] Token refresh failed: ${e.message}');
      }
      // Refresh token itself is invalid/expired/revoked -- clear the
      // session so the app falls back to the login screen cleanly
      // instead of retrying forever with a dead refresh token.
      await TokenStorage.clear();
      return null;
    }
  }

  Dio get dio => _dio;
}
