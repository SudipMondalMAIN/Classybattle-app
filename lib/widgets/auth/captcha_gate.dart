import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';

/// Cloudflare Turnstile site key (public, safe to ship in the app --
/// the secret key stays server-side only, see app/config/settings.py).
const String kTurnstileSiteKey = '0x4AAAAAAEnI5xidFgAqX-pj';

/// Wraps the Cloudflare Turnstile widget and hands back a fresh
/// captcha token on demand. Used on the login and signup screens right
/// before the final submit call so the backend (see
/// app/utils/captcha.py -> verify_captcha) can verify a real human is
/// submitting the request.
///
/// Renders invisibly (no visible checkbox) unless Cloudflare decides an
/// interactive challenge is needed, in which case it shows briefly.
class CaptchaGate extends StatefulWidget {
  const CaptchaGate({super.key, required this.onTokenReady});

  /// Called every time a fresh token is issued (on mount and whenever
  /// the previous token expires/refreshes).
  final ValueChanged<String?> onTokenReady;

  @override
  State<CaptchaGate> createState() => CaptchaGateState();
}

class CaptchaGateState extends State<CaptchaGate> {
  final TurnstileController _controller = TurnstileController();
  String? _token;

  /// Current token, if one has been issued. Screens should check this
  /// isn't null right before submitting; if it is, wait briefly and
  /// retry rather than submitting without one.
  String? get token => _token;

  /// Forces a fresh token (e.g. after a previous submit attempt failed
  /// captcha verification server-side).
  Future<void> refresh() async {
    _token = null;
    await _controller.refreshToken();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CloudFlareTurnstile(
      siteKey: kTurnstileSiteKey,
      // Must match a hostname configured on the Turnstile widget in the
      // Cloudflare dashboard (we added api.classybattle.online there).
      baseUrl: 'https://api.classybattle.online',
      mode: TurnstileMode.managed,
      controller: _controller,
      options: TurnstileOptions(
        size: TurnstileSize.normal,
        theme: TurnstileTheme.auto,
        retryAutomatically: true,
      ),
      onTokenRecived: (token) {
        _token = token;
        widget.onTokenReady(token);
      },
      onTokenExpired: () {
        _token = null;
        widget.onTokenReady(null);
      },
    );
  }
}
