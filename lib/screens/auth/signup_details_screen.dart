import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'signup_otp_screen.dart';

class SignupDetailsScreen extends StatefulWidget {
  const SignupDetailsScreen({super.key});

  @override
  State<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends State<SignupDetailsScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in every field.');
      return;
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authService.signup(
        fullName: name,
        email: email,
        phoneNumber: phone,
        password: password,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SignupOtpScreen(email: email)),
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
      title: 'Create your account',
      subtitle: "Enter your details to join ClassyBattle's tournaments.",
      showLogo: false,
      children: [
        AuthTextField(
          controller: _nameCtrl,
          label: 'Full name',
          hint: 'Your name',
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _phoneCtrl,
          label: 'Phone number',
          hint: '10-digit number',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.call_outlined,
          maxLength: 10,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _passwordCtrl,
          label: 'Password',
          hint: 'Create a password',
          obscureText: _obscure,
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
        AuthPrimaryButton(label: 'Continue', onPressed: _continue, loading: _loading),
      ],
    );
  }
}
