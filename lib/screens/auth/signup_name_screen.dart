import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_legal_footer.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'signup_otp_screen.dart';

/// Signup step 4 of 4: name. Submitting here calls the backend with all
/// four collected fields in one go (that's the only way it sends the
/// OTP — see AuthService.signup), then moves on to OTP verification.
class SignupNameScreen extends StatefulWidget {
  const SignupNameScreen({
    super.key,
    required this.email,
    required this.password,
    required this.phone,
  });

  final String email;
  final String password;
  final String phone;

  @override
  State<SignupNameScreen> createState() => _SignupNameScreenState();
}

class _SignupNameScreenState extends State<SignupNameScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your full name.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authService.signup(
        fullName: name,
        email: widget.email,
        phoneNumber: widget.phone,
        password: widget.password,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SignupOtpScreen(email: widget.email)),
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
      title: "What's your name?",
      subtitle: "Step 4 of 4 — last thing, we promise.",
      children: [
        AuthTextField(
          controller: _nameCtrl,
          label: 'Full name',
          hint: 'Your name',
          autofocus: true,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.person_outline_rounded,
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
        ],
        const SizedBox(height: 26),
        AuthPrimaryButton(label: 'Create account', onPressed: _submit, loading: _loading),
        const SizedBox(height: 20),
        const AuthLegalFooter(),
      ],
    );
  }
}
