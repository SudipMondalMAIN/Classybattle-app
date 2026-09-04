import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Tracks *actual* internet reachability, not just "connected to a
/// network". connectivity_plus alone only reports which interface is
/// active (wifi/mobile/none) -- it can't tell wifi-with-no-internet
/// or a captive portal apart from a real connection. This confirms
/// every change with a cheap DNS lookup against a public resolver
/// (never our own backend), so it can be checked as often as needed
/// without adding any load to our servers.
///
/// Purely event-driven: reacts to OS connectivity-change events plus
/// one check at startup. No periodic polling.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _debounce;
  bool? _lastStatus;
  bool _initialized = false;

  /// Emits on every *confirmed* status change (debounced + DNS
  /// verified). Never emits the same value twice in a row.
  Stream<bool> get onStatusChanged => _controller.stream;

  /// Last confirmed status. Only meaningful after [init] has
  /// completed at least once.
  bool get isOnline => _lastStatus ?? true;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Check immediately so a cold start with data/wifi already off
    // is reflected right away, instead of waiting for the first OS
    // connectivity-change event (which won't fire if it was already
    // off before the app launched).
    await _verifyAndEmit();

    _sub = _connectivity.onConnectivityChanged.listen((_) {
      // The OS fires this the instant the radio/interface changes
      // state, often before the interface actually has a working
      // route -- debounce briefly then confirm with a real lookup
      // rather than trusting the raw event.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), _verifyAndEmit);
    });
  }

  Future<void> _verifyAndEmit() async {
    final online = await _hasRealInternet();
    if (online == _lastStatus) return;
    _lastStatus = online;
    _controller.add(online);
  }

  Future<bool> _hasRealInternet() async {
    try {
      // A timeout here (very slow/unusable connection) is treated
      // the same as "offline" -- from the user's point of view a
      // connection too slow to resolve DNS in 4s isn't usable
      // either.
      final result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Manual re-check, e.g. a "Retry" tap on the offline banner.
  Future<void> checkNow() => _verifyAndEmit();

  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    _controller.close();
  }
}
