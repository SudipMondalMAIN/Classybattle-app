import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    this.enabled = true,
    this.onSubmitted,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofocus: autofocus,
            enabled: enabled,
            onSubmitted: onSubmitted,
            maxLength: maxLength,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            cursorColor: AppColors.purple,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, color: AppColors.textMuted, size: 20),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
