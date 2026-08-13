import 'package:flutter/material.dart';
import '../../providers/profile_providers.dart';
import '../../theme/app_theme.dart';

class ProfileTournamentTabs extends StatelessWidget {
  const ProfileTournamentTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ProfileTournamentTab selected;
  final ValueChanged<ProfileTournamentTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ProfileTournamentTab.values.map((tab) {
          final active = tab == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: active ? AppColors.purpleButton : null,
                  color: active ? null : AppColors.glassFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
