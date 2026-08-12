import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class _Shortcut {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _Shortcut(this.icon, this.label, this.iconColor);
}

/// Static navigation shortcuts into real app sections (not backend
/// content, so nothing here is "fake data" -- these map 1:1 to
/// existing screens/routes as they get built out).
class CategoryShortcuts extends StatelessWidget {
  const CategoryShortcuts({super.key, required this.onTap});

  final void Function(String label) onTap;

  static const _items = [
    _Shortcut(Icons.sports_esports_rounded, 'All Games', AppColors.purple),
    _Shortcut(Icons.emoji_events_rounded, 'Tournaments', AppColors.gold),
    _Shortcut(Icons.card_giftcard_rounded, 'Rewards', AppColors.success),
    _Shortcut(Icons.shield_rounded, 'Leaderboard', Color(0xFF4DA6FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items
            .map(
              (item) => GestureDetector(
                onTap: () => onTap(item.label),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.iconColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
