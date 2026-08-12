import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Cinematic purple energy / lightning glow that pulses behind the
/// trophy, roughly centered on where the trophy sits in the source
/// artwork (~38% down from the top). Restrained intensity — never
/// flashes to full white, just breathes.
class LightningGlowPainter extends CustomPainter {
  final double t; // 0..1 looping
  LightningGlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.30;
    final center = Offset(size.width * 0.5, centerY);

    // Slow double-sine breathing so it never feels metronomic.
    final pulse =
        (sin(t * 2 * pi) * 0.5 + 0.5) * 0.6 + (sin(t * 2 * pi * 1.7) * 0.5 + 0.5) * 0.4;
    final radius = size.width * (0.55 + pulse * 0.12);

    final glow = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          const Color(0xFFB18CFF).withValues(alpha: 0.16 + pulse * 0.10),
          const Color(0xFF7C3AED).withValues(alpha: 0.08 + pulse * 0.06),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      )
      ..blendMode = BlendMode.plus;

    canvas.drawCircle(center, radius, glow);

    // Occasional faint flicker streak (electrical), rare & subtle.
    final flickerPhase = (t * 3) % 1.0;
    if (flickerPhase < 0.06) {
      final streakOpacity = (0.06 - flickerPhase) / 0.06 * 0.10;
      final rng = Random((t * 1000).floor());
      final streakPaint = Paint()
        ..color = Colors.white.withValues(alpha: streakOpacity)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.plus;

      final path = Path();
      double x = center.dx + (rng.nextDouble() - 0.5) * size.width * 0.4;
      double y = centerY - radius * 0.3;
      path.moveTo(x, y);
      for (int i = 0; i < 5; i++) {
        x += (rng.nextDouble() - 0.5) * 40;
        y += radius * 0.15;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, streakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LightningGlowPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Slow-drifting purple embers/particles across the whole scene —
/// gives the atmosphere continuous, subtle life without being a
/// generic particle-system look.
class EmberParticlesPainter extends CustomPainter {
  final double t; // 0..1 looping
  final int count;
  final List<_Ember> _embers;

  EmberParticlesPainter(this.t, {this.count = 26})
      : _embers = _buildEmbers(count);

  static List<_Ember> _buildEmbers(int count) {
    final rng = Random(7);
    return List.generate(count, (i) {
      return _Ember(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.2 + rng.nextDouble() * 2.4,
        speed: 0.15 + rng.nextDouble() * 0.35,
        drift: (rng.nextDouble() - 0.5) * 0.06,
        phase: rng.nextDouble(),
        opacity: 0.25 + rng.nextDouble() * 0.45,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final e in _embers) {
      final localT = (t * e.speed + e.phase) % 1.0;
      // Rises upward slowly, gentle horizontal sway.
      final dy = (1.0 - localT) * size.height;
      final sway = sin((localT + e.phase) * 2 * pi) * e.drift * size.width;
      final dx = (e.x * size.width) + sway;

      final fade = sin(localT * pi); // fade in, fade out
      paint.color =
          const Color(0xFFCBB2FF).withValues(alpha: e.opacity * fade * 0.55);

      canvas.drawCircle(Offset(dx, dy), e.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EmberParticlesPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _Ember {
  final double x, y, size, speed, drift, phase, opacity;
  _Ember({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.opacity,
  });
}

/// Diagonal light sweep used across the CB logo / trophy highlight.
class LightSweepPainter extends CustomPainter {
  final double t; // 0..1, one full sweep per cycle
  final Rect bounds; // area (in local coords) the sweep is confined to
  LightSweepPainter(this.t, this.bounds);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(bounds);

    final sweepX = bounds.left + bounds.width * (t * 1.6 - 0.3);
    final rect = Rect.fromLTWH(
      sweepX - bounds.width * 0.25,
      bounds.top,
      bounds.width * 0.25,
      bounds.height,
    );

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.top),
        [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.plus;

    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LightSweepPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.bounds != bounds;
}
