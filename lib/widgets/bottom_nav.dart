import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.emoji_events_rounded, 'Tournaments'),
    (Icons.bolt_rounded, ''), // center highlighted
    (Icons.account_balance_wallet_rounded, 'Wallet'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GlassContainer(
        borderRadius: AppRadius.pill,
        blur: 24,
        opacity: 0.14,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: Border.all(color: AppColors.glassBorder, width: 1.2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_items.length, (i) {
            final isCenter = i == 2;
            final selected = currentIndex == i;
            if (isCenter) {
              return GestureDetector(
                onTap: () => onTap(i),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.55),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Icon(_items[i].$1, color: Colors.white, size: 24),
                ),
              );
            }
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  _items[i].$1,
                  color: selected ? Colors.white : AppColors.textMuted,
                  size: 22,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
