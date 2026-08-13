import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/otp_input.dart';
import '../../widgets/auth/resend_timer.dart';
import 'signup_success_screen.dart';

class SignupOtpScreen extends StatefulWidget {
  const SignupOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
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
      final result = await authService.verifySignupOtp(email: widget.email, otp: _otp);
      await authService.persistSession(result);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignupSuccessScreen()),
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
      await authService.resendOtp(email: widget.email, purpose: 'signup_verification');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify your email',
      subtitle: 'Enter the 6-digit code sent to ${widget.email}.',
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
