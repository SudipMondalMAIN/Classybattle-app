import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Core iOS-style glassmorphism surface: blurred backdrop + translucent
/// gradient fill + subtle top highlight border, like iOS Control Center
/// / widget cards.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.lg,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blur = 18,
    this.opacity = 0.10,
    this.tint,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (tint ?? Colors.white).withValues(alpha: opacity + 0.06),
                  (tint ?? Colors.white).withValues(alpha: opacity * 0.4),
                ],
              ),
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A frosted app background: gradient wash + soft glowing orbs, similar to
/// iOS wallpaper-behind-glass depth.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.screenGradient),
        ),
        Positioned(
          top: -80,
          left: -60,
          child: _Orb(color: AppColors.purple.withValues(alpha: 0.35), size: 260),
        ),
        Positioned(
          top: 180,
          right: -100,
          child: _Orb(color: AppColors.blue.withValues(alpha: 0.28), size: 300),
        ),
        Positioned(
          bottom: -60,
          left: -40,
          child: _Orb(color: AppColors.pink.withValues(alpha: 0.25), size: 240),
        ),
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// A glass "pill" chip — used for status badges, tags etc.
class GlassPill extends StatelessWidget {
  final String text;
  final Color color;
  const GlassPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppRadius.pill,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      blur: 10,
      opacity: 0.12,
      tint: color,
      border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      boxShadow: const [],
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
