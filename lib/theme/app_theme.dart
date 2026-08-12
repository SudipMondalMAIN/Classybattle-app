import 'package:flutter/material.dart';

/// Central color + text style tokens for ClassyBattle's dark,
/// purple-accented glassmorphism UI. Keep every raw color reference
/// here so screens/widgets never hardcode a hex value inline.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF0A0A16);
  static const Color backgroundGradientTop = Color(0xFF0E0B1F);
  static const Color backgroundGradientBottom = Color(0xFF06050D);

  // Glass surfaces
  static const Color glassFill = Color(0x14FFFFFF); // white @ 8%
  static const Color glassFillStrong = Color(0x1FFFFFFF); // white @ 12%
  static const Color glassBorder = Color(0x33FFFFFF); // white @ 20%
  static const Color glassBorderBright = Color(0x59A78BFA); // purple @ 35%

  // Brand purple
  static const Color purple = Color(0xFF7C5CFF);
  static const Color purpleDeep = Color(0xFF4A2FD6);
  static const Color purpleSoft = Color(0xFFB9A6FF);

  static const LinearGradient purpleButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8B6BFF), Color(0xFF5433D6)],
  );

  // Status / accent
  static const Color live = Color(0xFFFF3B30);
  static const Color gold = Color(0xFFFFC33D);
  static const Color success = Color(0xFF34C759);

  // Text
  static const Color textPrimary = Color(0xFFF5F4FA);
  static const Color textSecondary = Color(0xFFA6A3BD);
  static const Color textMuted = Color(0xFF6F6C88);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.purple,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.purple,
        secondary: AppColors.purpleSoft,
        surface: AppColors.background,
        error: AppColors.live,
      ),
      textTheme: base.textTheme
          .apply(
            fontFamily: 'Roboto',
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
