import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'signup_phone_screen.dart';

/// Signup step 2 of 4: password.
class SignupPasswordScreen extends StatefulWidget {
  const SignupPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<SignupPasswordScreen> createState() => _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends State<SignupPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    final password = _passwordCtrl.text;
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() => _error = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupPhoneScreen(email: widget.email, password: password),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create a password',
      subtitle: 'Step 2 of 4 — secure your account.',
      children: [
        AuthTextField(
          controller: _passwordCtrl,
          label: 'Password',
          hint: 'Create a password',
          obscureText: _obscure,
          autofocus: true,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline_rounded,
          onSubmitted: (_) => _continue(),
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
        ],
        const SizedBox(height: 26),
        AuthPrimaryButton(label: 'Continue', onPressed: _continue),
      ],
    );
  }
}
