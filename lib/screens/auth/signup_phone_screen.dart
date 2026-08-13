import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'signup_name_screen.dart';

/// Signup step 3 of 4: phone number.
class SignupPhoneScreen extends StatefulWidget {
  const SignupPhoneScreen({super.key, required this.email, required this.password});

  final String email;
  final String password;

  @override
  State<SignupPhoneScreen> createState() => _SignupPhoneScreenState();
}

class _SignupPhoneScreenState extends State<SignupPhoneScreen> {
  final _phoneCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    final phone = _phoneCtrl.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number.');
      return;
    }
    setState(() => _error = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupNameScreen(
          email: widget.email,
          password: widget.password,
          phone: phone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "What's your number?",
      subtitle: "Step 3 of 4 — we'll use this for match updates.",
      children: [
        AuthTextField(
          controller: _phoneCtrl,
          label: 'Phone number',
          hint: '10-digit number',
          keyboardType: TextInputType.phone,
          autofocus: true,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.call_outlined,
          maxLength: 10,
          onSubmitted: (_) => _continue(),
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
