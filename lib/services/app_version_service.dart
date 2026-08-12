import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../core/api_client.dart';
import '../models/app_version_check.dart';

/// Talks to the existing backend endpoint:
///   GET /api/v1/app/version/check?platform=android&current_version=X.Y.Z
///
/// See backend/app/api/v1/app_version_routes.py — this is the real,
/// already-implemented force-update system. No mock/dummy logic here.
class AppVersionService {
  AppVersionService._();

  static Future<AppVersionCheck> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await ApiClient.instance.dio.get(
        '/app/version/check',
        queryParameters: {
          'platform': platform,
          'current_version': info.version,
        },
      );

      return AppVersionCheck.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (_) {
      // Never block startup because the version check itself failed
      // (no network, backend momentarily down, etc).
      return AppVersionCheck.noop();
    }
  }
}
