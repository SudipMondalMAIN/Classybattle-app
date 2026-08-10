import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base backgrounds (deep navy-black, matching reference screens)
  static const Color bgTop = Color(0xFF0F0F1E);
  static const Color bgBottom = Color(0xFF07070F);
  static const Color surface = Color(0xFF14131F);
  static const Color surfaceLight = Color(0xFF1C1A2B);
  static const Color card = Color(0xFF15141F);
  static const Color cardBorder = Color(0xFF272536);

  // Brand gradient (indigo -> violet accents)
  static const Color purple = Color(0xFF6C5CE7);
  static const Color purpleDeep = Color(0xFF5A3FD6);
  static const Color pink = Color(0xFFE23FE0);
  static const Color blue = Color(0xFF4B6BFB);
  static const Color cyan = Color(0xFF33E1FF);

  static const Color textPrimary = Color(0xFFF5F4F8);
  static const Color textSecondary = Color(0xFF8D8AA0);
  static const Color textMuted = Color(0xFF64617A);

  static const Color success = Color(0xFF2ED573);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFFFB020);
  static const Color gold = Color(0xFFFFC93C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7A5CF0), Color(0xFF5B3FD6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient screenGradient = LinearGradient(
    colors: [bgTop, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2A1F4A), Color(0xFF1A1330)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism accents (iOS-style frosted glass)
  static const Color glassBorder = Color(0x33FFFFFF); // white @ 20%
  static const Color glassHighlight = Color(0x1AFFFFFF); // white @ 10%
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBottom,
      primaryColor: AppColors.purple,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.purple,
        secondary: AppColors.pink,
        surface: AppColors.surface,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: 'Roboto',
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 100;
}
