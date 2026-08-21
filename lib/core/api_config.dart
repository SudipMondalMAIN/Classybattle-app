/// Backend base URL configuration.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://your-api-host
///
/// Defaults to the deployed Render backend so the app works out of
/// the box on physical devices, simulators, and emulators alike.
/// Pass --dart-define=API_BASE_URL=http://10.0.2.2:8000 (Android
/// emulator) or http://127.0.0.1:8000 (iOS simulator) to point at a
/// local backend instead.
class ApiConfig {
  ApiConfig._();

  static const String _base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://classybattle.onrender.com',
  );

  /// e.g. http://10.0.2.2:8000/api/v1
  static String get baseUrl => '$_base/api/v1';

  /// Same host as [baseUrl] but with the scheme swapped for its
  /// WebSocket equivalent (https -> wss, http -> ws), used for the
  /// live support chat socket. e.g. wss://classybattle.onrender.com/api/v1
  static String get wsBaseUrl {
    if (_base.startsWith('https://')) {
      return 'wss://${_base.substring('https://'.length)}/api/v1';
    }
    if (_base.startsWith('http://')) {
      return 'ws://${_base.substring('http://'.length)}/api/v1';
    }
    return '$_base/api/v1';
  }
}