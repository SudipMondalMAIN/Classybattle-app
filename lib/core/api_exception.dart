import 'package:dio/dio.dart';

/// Normalizes Dio/backend errors into one type the UI can show directly.
///
/// The FastAPI backend returns errors as either:
///   { "detail": "Some message" }
///   { "detail": [ { "msg": "...", "loc": [...] }, ... ] }  (pydantic validation)
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException('Server e connect kora jaini. Internet ba server check koro.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException('Network error — internet connection check koro.');
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    String msg = 'Kichu ekta vul hoyeche. Abar chesta koro.';
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) {
        msg = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          msg = first['msg'].toString();
        } else {
          msg = detail.map((d) => d is Map ? d['msg'] ?? d.toString() : d.toString()).join(', ');
        }
      }
    }
    return ApiException(msg, statusCode: status);
  }

  @override
  String toString() => message;
}
