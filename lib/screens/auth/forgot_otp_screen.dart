import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/otp_input.dart';
import '../../widgets/auth/resend_timer.dart';
import 'reset_password_screen.dart';

class ForgotOtpScreen extends StatefulWidget {
  const ForgotOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<ForgotOtpScreen> createState() => _ForgotOtpScreenState();
}

class _ForgotOtpScreenState extends State<ForgotOtpScreen> {
  final _otpKey = GlobalKey<OtpInputState>();
  String _otp = '';
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authService.verifyResetOtp(email: widget.email, otp: _otp);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email, otp: _otp),
        ),
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
      await authService.resendOtp(email: widget.email, purpose: 'password_reset');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Enter the code',
      subtitle: 'We sent a 6-digit code to ${widget.email}.',
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
        AuthPrimaryButton(label: 'Verify', onPressed: _verify, loading: _loading),
        const SizedBox(height: 20),
        ResendTimer(onResend: _resend),
      ],
    );
  }
}
