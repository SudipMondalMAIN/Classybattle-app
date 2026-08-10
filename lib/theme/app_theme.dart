import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base backgrounds
  static const Color bgTop = Color(0xFF120B26);
  static const Color bgBottom = Color(0xFF0A0714);
  static const Color surface = Color(0xFF1B1330);
  static const Color surfaceLight = Color(0xFF241A3E);
  static const Color card = Color(0xFF1E1636);
  static const Color cardBorder = Color(0xFF352A54);

  // Brand gradient (purple -> pink/blue accents)
  static const Color purple = Color(0xFF7B2FF7);
  static const Color purpleDeep = Color(0xFF5B1FD6);
  static const Color pink = Color(0xFFE23FE0);
  static const Color blue = Color(0xFF3F8CFF);
  static const Color cyan = Color(0xFF33E1FF);

  static const Color textPrimary = Color(0xFFF5F3FA);
  static const Color textSecondary = Color(0xFFA79BC4);
  static const Color textMuted = Color(0xFF6F6390);

  static const Color success = Color(0xFF2ED573);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFFFB020);
  static const Color gold = Color(0xFFFFC93C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, pink],
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
