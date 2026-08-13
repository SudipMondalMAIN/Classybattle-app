import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'forgot_otp_screen.dart';

class ForgotEmailScreen extends StatefulWidget {
  const ForgotEmailScreen({super.key});

  @override
  State<ForgotEmailScreen> createState() => _ForgotEmailScreenState();
}

class _ForgotEmailScreenState extends State<ForgotEmailScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your account email.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authService.forgotPassword(email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ForgotOtpScreen(email: email)),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset your password',
      subtitle: "Enter the email on your account and we'll send you a code.",
      showLogo: false,
      children: [
        AuthTextField(
          controller: _emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.mail_outline_rounded,
          onSubmitted: (_) => _sendOtp(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
        ],
        const SizedBox(height: 26),
        AuthPrimaryButton(label: 'Send OTP', onPressed: _sendOtp, loading: _loading),
      ],
    );
  }
}
