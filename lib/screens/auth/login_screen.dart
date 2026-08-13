import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../home_screen.dart';
import 'forgot_email_screen.dart';
import 'signup_details_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await authService.login(email: email, password: password);
      await authService.persistSession(result);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      title: 'Welcome back',
      subtitle: 'Log in to keep competing on ClassyBattle.',
      showBack: false,
      children: [
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
          controller: _passwordCtrl,
          label: 'Password',
          hint: 'Enter your password',
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline_rounded,
          onSubmitted: (_) => _login(),
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _loading
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotEmailScreen()),
                    ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                color: AppColors.purpleSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(label: 'Login', onPressed: _login, loading: _loading),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? ",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            GestureDetector(
              onTap: _loading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupDetailsScreen()),
                      ),
              child: const Text(
                'Sign up',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
