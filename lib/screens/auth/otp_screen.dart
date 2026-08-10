import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../root_shell.dart';
import 'auth_widgets.dart';
import 'reset_password_screen.dart';

enum OtpPurpose { signup, passwordReset }

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  final OtpPurpose purpose;

  const OtpScreen({super.key, required this.email, required this.purpose});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _resending = false;
  int _cooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _cooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown == 0) {
        t.cancel();
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _backendPurpose =>
      widget.purpose == OtpPurpose.signup ? 'signup_verification' : 'password_reset';

  Future<void> _resend() async {
    setState(() => _resending = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resendOtp(email: widget.email, purpose: _backendPurpose);
    if (!mounted) return;
    setState(() => _resending = false);
    if (ok) {
      showAuthSnack(context, 'OTP abar pathano hoyeche', isError: false);
      _startCooldown();
    } else {
      showAuthSnack(context, ref.read(authControllerProvider).error ?? 'Resend failed');
    }
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.trim().length < 4) {
      showAuthSnack(context, 'Valid OTP dao');
      return;
    }
    setState(() => _loading = true);

    if (widget.purpose == OtpPurpose.signup) {
      final ok = await ref
          .read(authControllerProvider.notifier)
          .verifySignupOtp(email: widget.email, otp: _otpCtrl.text.trim());
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RootShell()),
          (route) => false,
        );
      } else {
        showAuthSnack(context, ref.read(authControllerProvider).error ?? 'OTP verify failed');
      }
    } else {
      try {
        await _authService.verifyResetOtp(email: widget.email, otp: _otpCtrl.text.trim());
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: widget.email, otp: _otpCtrl.text.trim()),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        showAuthSnack(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.screenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text('OTP Verify koro',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '${widget.email} e ekta OTP pathano hoyeche',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _otpCtrl,
                  label: 'OTP Code',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 28),
                _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: AppColors.purple),
                        ),
                      )
                    : GradientButton(label: 'Verify Koro', height: 52, onTap: _verify),
                const SizedBox(height: 16),
                Center(
                  child: _cooldown > 0
                      ? Text('Abar OTP pabe $_cooldown sec e',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
                      : TextButton(
                          onPressed: _resending ? null : _resend,
                          child: Text(
                            _resending ? 'Pathano hocche...' : 'OTP abar pathao',
                            style: const TextStyle(color: AppColors.cyan),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
