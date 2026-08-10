/// Central place for backend connection settings.
///
/// TODO(Sudip): set [prodBaseUrl] to your deployed Render URL, e.g.
/// "https://classybattle-api.onrender.com/api/v1"
class ApiConfig {
  ApiConfig._();

  /// Deployed backend is live, so default to it — no emulator IP juggling needed.
  /// Flip to false only if you're running the backend locally for debugging.
  static const bool useProd = true;

  /// Android emulator loopback to your local machine's 127.0.0.1.
  /// If you're running on a real device on the same Wi-Fi, replace this
  /// with your PC's LAN IP, e.g. "http://192.168.1.5:8000/api/v1".
  static const String _devBaseUrl = 'http://10.0.2.2:8000/api/v1';

  static const String _prodBaseUrl = 'https://classybattle.onrender.com/api/v1';

  static String get baseUrl => useProd ? _prodBaseUrl : _devBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
