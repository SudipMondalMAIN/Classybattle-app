import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dark frosted-glass card: blurred translucent fill, thin bright
/// border, soft outer glow. Used for every "glass" surface in the
/// Home Screen (header chips, hero card, category card, tournament
/// cards, bottom nav).
///
/// PERFORMANCE: the default blurSigma runs a real BackdropFilter blur
/// every frame this widget is on screen -- expensive, especially on
/// mid/low-end Android. Fine for a one-off surface (a header, a modal,
/// a bottom nav). For any widget repeated inside a ListView/GridView
/// (a card per item), pass `blurSigma: 0` -- the flat fillColor alone
/// reads as "glass" against this app's gradient background, and it
/// removes one blur pass per visible card per scroll frame.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blurSigma = 16,
    this.fillColor,
    this.borderColor,
    this.glow = false,
    this.margin,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? fillColor;
  final Color? borderColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      margin: margin,
      decoration: glow
          ? BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        // RepaintBoundary isolates this blur's repaint from the rest of
        // the tree — without it, every scroll frame can force nearby
        // glass surfaces to re-run their (expensive) blur pass too.
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: fillColor ?? AppColors.glassFill,
                borderRadius: radius,
                border: Border.all(
                  color: borderColor ?? AppColors.glassBorder,
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
