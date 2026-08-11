import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.emoji_events_rounded, 'Tournaments'),
    (Icons.account_balance_wallet_rounded, 'Wallet'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10 + MediaQuery.of(context).padding.bottom * 0.4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (i) {
          final selected = currentIndex == i;
          final color = selected ? AppColors.purple : AppColors.textMuted;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_items[i].$1, color: color, size: 23),
                const SizedBox(height: 4),
                Text(
                  _items[i].$2,
                  style: TextStyle(
                      color: color, fontSize: 10.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
