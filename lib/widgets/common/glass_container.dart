import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dark frosted-glass-look card: translucent fill, thin bright border,
/// soft outer glow. Used for every "glass" surface in the app (header
/// chips, hero card, category card, tournament cards, bottom nav).
///
/// PERFORMANCE: blurSigma defaults to 0 (no real-time blur). A real
/// BackdropFilter blur was causing noticeable lag/jank when scrolling
/// and switching tabs, since many GlassContainers are often on screen
/// at once. The flat, semi-transparent fillColor alone reads as
/// "glass" against this app's gradient background without the per-
/// frame blur cost. Pass a positive blurSigma only for a one-off
/// surface where the extra blur is worth it (rare).
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blurSigma = 0,
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
    final content = Container(
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
    );

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
      child: blurSigma <= 0
          ? ClipRRect(borderRadius: radius, child: content)
          : ClipRRect(
              borderRadius: radius,
              // RepaintBoundary isolates this blur's repaint from the
              // rest of the tree -- without it, every scroll frame can
              // force nearby glass surfaces to re-run their blur too.
              child: RepaintBoundary(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: content,
                ),
              ),
            ),
    );
  }
}
