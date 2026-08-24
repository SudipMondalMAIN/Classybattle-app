/// Mirrors backend `MaintenanceCheckResponse`
/// (app/schemas/maintenance.py) exactly — do not add fields the
/// backend doesn't send. Deliberately tiny and separate from
/// AppVersionCheck.
class MaintenanceCheck {
  final bool isEnabled;
  final String title;
  final String message;
  final String statusUrl;

  const MaintenanceCheck({
    required this.isEnabled,
    required this.title,
    required this.message,
    required this.statusUrl,
  });

  factory MaintenanceCheck.fromJson(Map<String, dynamic> json) {
    return MaintenanceCheck(
      isEnabled: json['is_enabled'] as bool? ?? false,
      title: json['title'] as String? ?? 'Under Maintenance',
      message: json['message'] as String? ??
          'ClassyBattle is currently undergoing scheduled maintenance. '
              'Please check back shortly.',
      statusUrl: json['status_url'] as String? ??
          'https://status.classybattle.online',
    );
  }

  /// Safe fallback used when the check fails (offline, backend down,
  /// etc). We never block the user from entering the app just
  /// because the maintenance-check call itself failed.
  factory MaintenanceCheck.noop() => const MaintenanceCheck(
        isEnabled: false,
        title: '',
        message: '',
        statusUrl: '',
      );
}
