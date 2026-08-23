import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/otp_input.dart';
import '../../widgets/auth/resend_timer.dart';
import '../home_screen.dart';

/// OTP-based alternative to LoginPasswordScreen. Reached with the email
/// already known; sends a login OTP immediately on entry, then verifies
/// it. Backend caps requests at settings.LOGIN_OTP_RATE_LIMIT (2 per 5
/// minutes per IP) -- a rapid-fire resend here will surface that as a
/// normal AuthException message rather than actually spamming the inbox.
class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _otpKey = GlobalKey<OtpInputState>();
  String _otp = '';
  bool _loading = false;
  bool _sending = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendInitialOtp();
  }

  Future<void> _sendInitialOtp() async {
    try {
      await authService.requestLoginOtp(widget.email);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (_loading) return; // guard against double-submit (keyboard/OTP
    // auto-complete firing alongside a button tap) sending duplicate
    // verify requests.
    if (_otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await authService.verifyLoginOtp(email: widget.email, otp: _otp);
      await authService.persistSession(result);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
      _otpKey.currentState?.clear();
      _otp = '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await authService.requestLoginOtp(widget.email);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Enter login code',
      subtitle: _sending
          ? 'Sending a code to ${widget.email}...'
          : 'Enter the 6-digit code sent to ${widget.email}.',
      children: [
        OtpInput(
          key: _otpKey,
          length: 6,
          hasError: _error != null,
          onChanged: (v) {
            _otp = v;
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: (v) {
            _otp = v;
            _verify();
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(label: 'Login', onPressed: _verify, loading: _loading),
        const SizedBox(height: 20),
        ResendTimer(onResend: _resend),
      ],
    );
  }
}
