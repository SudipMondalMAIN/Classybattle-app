import 'dart:math';

import 'package:flutter/material.dart';

import 'splash_fx_painters.dart';

/// Turns the static ClassyBattle poster artwork into a living scene.
///
/// Implementation note: the source is a single flattened PNG (no
/// separate PSD layers for each character/flag/helicopter were
/// provided), so true per-sprite extraction isn't possible without
/// re-authoring the art. To still satisfy "elements move, not one
/// flat image", this widget combines:
///   - a slow multi-axis Ken Burns drift+scale on the artwork itself
///     (gives the whole scene parallax-like depth against the FX
///     layers, which do NOT move with the image),
///   - an independent purple lightning/energy glow layer pulsing
///     behind the trophy,
///   - an independent slow-drifting ember/particle layer across the
///     full scene,
///   - an independent diagonal light-sweep layer confined to the
///     logo/trophy band,
///   - a staged reveal (dark -> environment -> logo emphasis -> full
///     scene) driven by the same controller, matching the requested
///     0-3s startup timing.
/// Each layer runs on its own transform/paint pass, so they move
/// independently of one another and of the base artwork.
class AnimatedSplashScene extends StatefulWidget {
  const AnimatedSplashScene({super.key});

  @override
  State<AnimatedSplashScene> createState() => _AnimatedSplashSceneState();
}

class _AnimatedSplashSceneState extends State<AnimatedSplashScene>
    with TickerProviderStateMixin {
  // Drives the one-shot 0-3s reveal sequence.
  late final AnimationController _revealCtrl;
  // Continuous slow loops for ambient life (separate ticker so the
  // reveal finishing doesn't stop the scene from breathing).
  late final AnimationController _loopCtrl;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _loopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_revealCtrl, _loopCtrl]),
      builder: (context, _) {
        final reveal = _revealCtrl.value;
        final loop = _loopCtrl.value;

        // --- staged reveal curves -------------------------------------
        final darkToScene = Curves.easeOut.transform(
          (reveal / 0.55).clamp(0.0, 1.0),
        ); // 0.0-1.4s: atmosphere fades up
        final glowRamp = Curves.easeIn.transform(
          ((reveal - 0.20) / 0.55).clamp(0.0, 1.0),
        ); // 0.5-1.2s: purple lighting begins
        final logoEmphasis = Curves.easeOutBack.transform(
          ((reveal - 0.46) / 0.24).clamp(0.0, 1.0),
        ); // 1.2-1.8s: CB logo pops
        final finalGlow = Curves.easeOut.transform(
          ((reveal - 0.80) / 0.20).clamp(0.0, 1.0),
        ); // 2.4-3.0s: final premium glow

        // --- continuous ambient motion ----------------------------------
        // Slow Ken Burns: gentle scale + drift, two overlapping sine
        // waves so it never feels like a mechanical loop.
        final breatheScale = 1.045 +
            sin(loop * 2 * pi) * 0.012 +
            sin(loop * 2 * pi * 0.37) * 0.006;
        final driftX = sin(loop * 2 * pi * 0.5) * 6.0;
        final driftY = cos(loop * 2 * pi * 0.33) * 4.0;

        // Logo subtle premium pulse (independent short cycle).
        final logoPulse = 1.0 + sin(loop * 2 * pi * 2.1) * 0.012;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base artwork — the visual source of truth. Its own
            // slow drift/scale layer.
            Opacity(
              opacity: darkToScene.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(driftX, driftY),
                child: Transform.scale(
                  scale: breatheScale,
                  child: Image.asset(
                    'assets/images/splash_scene.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Dark atmospheric vignette that recedes as the scene
            // reveals (0.0-0.5s requirement: dark -> visible).
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(
                        alpha: (1.0 - darkToScene) * 0.85,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Independent lightning / purple energy layer, centered
            // on the trophy band.
            IgnorePointer(
              child: Opacity(
                opacity: glowRamp,
                child: CustomPaint(
                  painter: LightningGlowPainter(loop),
                  size: Size.infinite,
                ),
              ),
            ),

            // Independent slow ember/particle drift across the
            // whole frame.
            IgnorePointer(
              child: Opacity(
                opacity: glowRamp * 0.9,
                child: CustomPaint(
                  painter: EmberParticlesPainter(loop),
                  size: Size.infinite,
                ),
              ),
            ),

            // Logo emphasis: subtle scale pop-in + soft rim glow,
            // confined to the central logo band (~34%-52% height),
            // independent of the base image's own drift.
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final logoBand = Rect.fromLTWH(
                  w * 0.18,
                  h * 0.34,
                  w * 0.64,
                  h * 0.18,
                );
                return IgnorePointer(
                  child: Opacity(
                    opacity: (0.35 + 0.65 * logoEmphasis).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: (0.94 + 0.06 * logoEmphasis) * logoPulse,
                      alignment: Alignment(0, -0.05),
                      child: CustomPaint(
                        painter: LightSweepPainter(loop * 0.6 % 1.0, logoBand),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Final premium glow wash, brief and restrained.
            IgnorePointer(
              child: Opacity(
                opacity: finalGlow * 0.18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.9,
                      colors: [
                        const Color(0xFFB18CFF).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
