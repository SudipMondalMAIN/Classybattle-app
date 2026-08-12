/// Mirrors backend `AppVersionCheckResponse`
/// (app/schemas/app_version.py) exactly — do not add fields the
/// backend doesn't send.
class AppVersionCheck {
  final bool updateAvailable;
  final bool forceUpdate;
  final String latestVersion;
  final String updateUrl;
  final String updateTitle;
  final String updateMessage;

  const AppVersionCheck({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.latestVersion,
    required this.updateUrl,
    required this.updateTitle,
    required this.updateMessage,
  });

  factory AppVersionCheck.fromJson(Map<String, dynamic> json) {
    return AppVersionCheck(
      updateAvailable: json['update_available'] as bool? ?? false,
      forceUpdate: json['force_update'] as bool? ?? false,
      latestVersion: json['latest_version'] as String? ?? '',
      updateUrl: json['update_url'] as String? ?? '',
      updateTitle: json['update_title'] as String? ?? 'Update Available',
      updateMessage: json['update_message'] as String? ??
          'A new version of the app is available.',
    );
  }

  /// Safe fallback used when the check fails (offline, backend down,
  /// etc). We never block the user from entering the app just
  /// because the version-check call itself failed.
  factory AppVersionCheck.noop() => const AppVersionCheck(
        updateAvailable: false,
        forceUpdate: false,
        latestVersion: '',
        updateUrl: '',
        updateTitle: '',
        updateMessage: '',
      );
}
