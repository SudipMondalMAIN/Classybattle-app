/// Backend base URL configuration.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://your-api-host
///
/// Defaults to the Android emulator's alias for the host machine's
/// localhost (10.0.2.2) since that's the common local-dev setup for
/// this backend (see Classybattle/docker-compose.yml, default port 8000).
/// Physical devices / iOS simulator / prod builds must pass the real
/// value via --dart-define.
class ApiConfig {
  ApiConfig._();

  static const String _base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// e.g. http://10.0.2.2:8000/api/v1
  static String get baseUrl => '$_base/api/v1';
}
