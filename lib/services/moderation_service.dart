import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/report_model.dart';
import 'home_service.dart' show UnauthenticatedException;

/// Thrown when a report submission fails for a known, user-facing
/// reason (e.g. tournament not live yet, so not reportable).
class SubmitReportException implements Exception {
  SubmitReportException(this.message);
  final String message;
}

class ModerationService {
  ModerationService(this._dio);

  final Dio _dio;

  /// POST /reports -- reports are permanent once a tournament goes
  /// live (published_at set); there's no time limit after that, so a
  /// tournament stays reportable for its lifetime.
  Future<void> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      await _dio.post(
        '/reports',
        data: {
          'target_type': targetType.wireValue,
          'target_id': targetId,
          'reason': reason.wireValue,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw SubmitReportException(
        detail?.toString() ?? 'Could not submit the report right now.',
      );
    }
  }
}

final moderationService = ModerationService(ApiClient.instance.dio);
