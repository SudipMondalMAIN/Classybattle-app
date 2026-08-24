import '../core/api_client.dart';
import '../models/maintenance_check.dart';

/// Talks to the existing backend endpoint:
///   GET /app/maintenance/check
///
/// See backend/app/api/v1/maintenance_routes.py — this is the real,
/// already-implemented maintenance kill-switch. Completely separate
/// from AppVersionService/force-update; no mock/dummy logic here.
class MaintenanceService {
  MaintenanceService._();

  static Future<MaintenanceCheck> check() async {
    try {
      final response = await ApiClient.instance.dio.get(
        '/app/maintenance/check',
      );

      return MaintenanceCheck.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (_) {
      // Never block startup because the maintenance check itself
      // failed (no network, backend momentarily down, etc).
      return MaintenanceCheck.noop();
    }
  }
}
