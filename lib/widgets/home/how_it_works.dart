import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class _Step {
  final String number;
  final String title;
  final String subtitle;
  const _Step(this.number, this.title, this.subtitle);
}

/// Static explainer copy describing the app's flow -- not
/// backend-driven content, so it's fine as fixed text (matches the
/// reference's "How It Works?" section).
class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  static const _steps = [
    _Step('1', 'Register', 'Join tournament'),
    _Step('2', 'Compete', 'Play your matches'),
    _Step('3', 'Score', 'Top the leaderboard'),
    _Step('4', 'Win', 'Get exciting prizes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How It Works?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: List.generate(_steps.length, (i) {
            final step = _steps[i];
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            gradient: AppColors.purpleButton,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            step.number,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != _steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 42),
                      child: SizedBox(
                        width: 18,
                        child: CustomPaint(painter: _DottedLinePainter()),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
