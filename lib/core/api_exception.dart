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
      return ApiException('Could not connect to server. Check your internet or server status.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException('Network error — check your internet connection.');
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    String msg = 'Something went wrong. Please try again.';
    if (data is Map) {
      final detail = data['detail'];
      final message = data['message'];
      if (detail is String) {
        msg = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          msg = first['msg'].toString();
        } else {
          msg = detail.map((d) => d is Map ? d['msg'] ?? d.toString() : d.toString()).join(', ');
        }
      } else if (message is String) {
        // Backend's custom AppException handler returns {"message": "..."}
        // instead of FastAPI's default {"detail": "..."} shape.
        msg = message;
      }
    }
    return ApiException(msg, statusCode: status);
  }

  @override
  String toString() => message;
}
