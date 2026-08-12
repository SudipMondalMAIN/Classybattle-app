import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Single shared Dio instance for the whole app. Attaches the bearer
/// token (when one exists) to every request; endpoints that don't
/// require auth simply ignore the header on the backend side.
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
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API] !! ${error.requestOptions.uri} -> '
              '${error.type} ${error.message}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;
}
