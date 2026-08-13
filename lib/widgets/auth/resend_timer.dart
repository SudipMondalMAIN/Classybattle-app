import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ResendTimer extends StatefulWidget {
  const ResendTimer({
    super.key,
    required this.onResend,
    this.seconds = 30,
  });

  final Future<void> Function() onResend;
  final int seconds;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  late int _remaining = widget.seconds;
  Timer? _timer;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _remaining = widget.seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await widget.onResend();
      if (mounted) _start();
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remaining <= 0 && !_resending;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Didn't receive the code? ",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        GestureDetector(
          onTap: canResend ? _resend : null,
          child: Text(
            canResend ? 'Resend' : 'Resend in ${_remaining}s',
            style: TextStyle(
              color: canResend ? AppColors.purple : AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
