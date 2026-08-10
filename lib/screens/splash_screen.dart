import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Logo entrance: scale + fade
  late final AnimationController _introController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // Continuous soft glow pulse behind the shield
  late final AnimationController _glowController;

  // Loading bar shimmer sweep
  late final AnimationController _barController;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _logoScale = CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _introController, curve: const Interval(0.35, 0.8, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic)),
    );

    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

    _barController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

    _introController.forward();

    // Hand off to the app shell once the intro has played out.
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const RootShell()),
        ),
      );
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _glowController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF060309),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Base dark radial backdrop
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 1.2,
                colors: [Color(0xFF1A0F33), Color(0xFF060309)],
                stops: [0.0, 0.85],
              ),
            ),
          ),
          // Faint drifting streaks for a bit of life
          ..._buildStreaks(size),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 28),
                _buildTitle(),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _textFade,
                  child: const Text(
                    'C O M P E T E   •   C O N Q U E R   •   W I N',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 60,
            right: 60,
            bottom: 70,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  _buildLoadingBar(),
                  const SizedBox(height: 14),
                  const Text('LOADING...',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _glowController]),
      builder: (context, child) {
        final glow = 0.35 + (_glowController.value * 0.35); // 0.35 -> 0.7
        return Opacity(
          opacity: _logoFade.value,
          child: Transform.scale(
            scale: 0.6 + (_logoScale.value * 0.4),
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.purple.withValues(alpha: glow), blurRadius: 60, spreadRadius: 4),
                  BoxShadow(color: AppColors.blue.withValues(alpha: glow * 0.6), blurRadius: 90, spreadRadius: 10),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(150, 165),
                  painter: _ShieldPainter(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _textFade,
      child: SlideTransition(
        position: _textSlide,
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Colors.white, AppColors.purple, AppColors.blue],
            stops: [0.0, 0.55, 1.0],
          ).createShader(rect),
          child: const Text(
            'CLASSYBATTLE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 3,
        color: Colors.white.withValues(alpha: 0.08),
        child: AnimatedBuilder(
          animation: _barController,
          builder: (context, _) {
            return Align(
              alignment: Alignment(-1 + (_barController.value * 2), 0),
              child: FractionallySizedBox(
                widthFactor: 0.35,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, AppColors.purple, AppColors.cyan, Colors.transparent],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildStreaks(Size size) {
    final streaks = [
      (0.15, 0.12, 90.0, AppColors.purple),
      (0.82, 0.32, 70.0, AppColors.blue),
      (0.1, 0.78, 60.0, AppColors.purple),
      (0.88, 0.65, 55.0, AppColors.cyan),
    ];
    return streaks.map((s) {
      return Positioned(
        left: size.width * s.$1,
        top: size.height * s.$2,
        child: Transform.rotate(
          angle: -math.pi / 5,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) => Container(
              width: 1.4,
              height: s.$3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, (s.$4 as Color).withValues(alpha: 0.25 + _glowController.value * 0.2), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Draws a shield outline with two crossed swords inside, in the same
/// silver/purple/blue palette as the reference art. Fully vector so no
/// image assets are needed.
class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.92, h * 0.16)
      ..lineTo(w * 0.92, h * 0.55)
      ..cubicTo(w * 0.92, h * 0.8, w * 0.74, h * 0.94, w * 0.5, h)
      ..cubicTo(w * 0.26, h * 0.94, w * 0.08, h * 0.8, w * 0.08, h * 0.55)
      ..lineTo(w * 0.08, h * 0.16)
      ..close();

    final shieldFill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF241A3E), Color(0xFF0E0A1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldFill);

    final shieldBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..shader = const LinearGradient(
        colors: [AppColors.purple, AppColors.blue],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldBorder);

    // Crossed swords
    void drawSword(Offset from, Offset to) {
      final bladePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(colors: [Colors.white, Color(0xFFC9C3E8)])
            .createShader(Rect.fromPoints(from, to));
      canvas.drawLine(from, to, bladePaint);

      // hilt guard near the "to" end
      final dir = (to - from);
      final unit = dir / dir.distance;
      final perp = Offset(-unit.dy, unit.dx);
      final guardCenter = to - unit * 14;
      final guardPaint = Paint()
        ..color = AppColors.purple
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(guardCenter - perp * 10, guardCenter + perp * 10, guardPaint);

      // pommel
      canvas.drawCircle(to, 4, Paint()..color = Colors.white);
    }

    final center = Offset(w / 2, h * 0.46);
    drawSword(center + const Offset(-38, 40), center + const Offset(38, -46));
    drawSword(center + const Offset(38, 40), center + const Offset(-38, -46));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
