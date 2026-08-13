import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter a new password.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset. Please log in again.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
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
      title: 'Set a new password',
      subtitle: 'Choose a new password for ${widget.email}.',
      showLogo: false,
      children: [
        AuthTextField(
          controller: _passwordCtrl,
          label: 'New password',
          hint: 'Enter new password',
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _confirmCtrl,
          label: 'Confirm password',
          hint: 'Re-enter new password',
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline_rounded,
          onSubmitted: (_) => _reset(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
        ],
        const SizedBox(height: 26),
        AuthPrimaryButton(label: 'Reset password', onPressed: _reset, loading: _loading),
      ],
    );
  }
}
