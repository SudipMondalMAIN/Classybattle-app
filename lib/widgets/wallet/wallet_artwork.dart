import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Small purple leather wallet with a "CB" hex badge and a stack of
/// gold coins peeking out the top -- built from shapes/gradients so
/// the balance card never depends on a bundled or placeholder image.
class WalletArtwork extends StatelessWidget {
  const WalletArtwork({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Ambient purple glow behind everything.
          Positioned(
            bottom: size * 0.1,
            child: Container(
              width: size * 0.75,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withValues(alpha: 0.35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.45),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          // Coin stack, behind + above the wallet body.
          Positioned(
            top: 0,
            child: _CoinStack(size: size),
          ),
          // Wallet body.
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.78,
              height: size * 0.56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5B3FD6), Color(0xFF2B1A66)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Snap/clasp dot.
                  Positioned(
                    top: size * 0.06,
                    right: size * 0.08,
                    child: Container(
                      width: size * 0.06,
                      height: size * 0.06,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  // "CB" hex badge.
                  Container(
                    width: size * 0.34,
                    height: size * 0.34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.purpleSoft.withValues(alpha: 0.8),
                        width: 1.4,
                      ),
                    ),
                    child: Text(
                      'CB',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinStack extends StatelessWidget {
  const _CoinStack({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final coinSize = size * 0.32;
    return SizedBox(
      width: size * 0.7,
      height: coinSize * 1.7,
      child: Stack(
        children: [
          Positioned(left: 0, top: coinSize * 0.35, child: _Coin(size: coinSize * 0.85)),
          Positioned(right: 0, top: coinSize * 0.25, child: _Coin(size: coinSize * 0.85)),
          Positioned(left: size * 0.19, top: 0, child: _Coin(size: coinSize)),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFE9A8), Color(0xFFE0A83B)],
          center: Alignment(-0.3, -0.3),
        ),
        border: Border.all(color: const Color(0xFFB9832A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.currency_rupee_rounded, size: size * 0.5, color: const Color(0xFF8A5A17)),
    );
  }
}
