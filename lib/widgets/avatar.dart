import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The backend only supports 6 fixed preset avatars (avatar_1..avatar_6, see
/// VALID_AVATAR_IDS in app/schemas/user.py) — no custom photo upload. This
/// renders each preset as a distinct colored glyph so we don't need bundled
/// PNG assets to stay accurate to what the backend actually stores.
class AvatarPreset {
  final String id;
  final Color color;
  final IconData icon;
  const AvatarPreset(this.id, this.color, this.icon);
}

const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset('avatar_1', AppColors.purple, Icons.sports_esports_rounded),
  AvatarPreset('avatar_2', AppColors.pink, Icons.local_fire_department_rounded),
  AvatarPreset('avatar_3', AppColors.blue, Icons.bolt_rounded),
  AvatarPreset('avatar_4', AppColors.cyan, Icons.shield_rounded),
  AvatarPreset('avatar_5', AppColors.gold, Icons.emoji_events_rounded),
  AvatarPreset('avatar_6', AppColors.success, Icons.rocket_launch_rounded),
];

AvatarPreset avatarForId(String? id) {
  return kAvatarPresets.firstWhere((a) => a.id == id, orElse: () => kAvatarPresets[0]);
}

class UserAvatar extends StatelessWidget {
  final String? avatarId;
  final String fallbackInitial;
  final double size;
  final VoidCallback? onEditTap;

  const UserAvatar({
    super.key,
    required this.avatarId,
    required this.fallbackInitial,
    this.size = 72,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final preset = avatarForId(avatarId);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: preset.color.withValues(alpha: 0.18),
              border: Border.all(color: preset.color.withValues(alpha: 0.7), width: 2),
              boxShadow: [
                BoxShadow(color: preset.color.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 1),
              ],
            ),
            alignment: Alignment.center,
            child: avatarId == null
                ? Text(fallbackInitial,
                    style: TextStyle(
                        color: preset.color, fontSize: size * 0.36, fontWeight: FontWeight.w800))
                : Icon(preset.icon, color: preset.color, size: size * 0.44),
          ),
          if (onEditTap != null)
            Positioned(
              bottom: -2,
              right: -2,
              child: GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.textPrimary, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
