import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    required this.onEditProfile,
    required this.onChangeAvatar,
  });

  final UserModel user;
  final VoidCallback onEditProfile;
  final VoidCallback onChangeAvatar;

  void _copyUid(BuildContext context) {
    Clipboard.setData(ClipboardData(text: user.playerUid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(user: user, onEdit: onChangeAvatar),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (user.isEmailVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              size: 18, color: AppColors.purple),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _copyUid(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'UID: ${user.playerUid}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy_rounded,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onEditProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purpleSoft,
                side: const BorderSide(color: AppColors.glassBorderBright),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.onEdit});

  final UserModel user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderBright, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: user.avatarId != null
                  ? Image.asset(
                      'assets/avatars/${user.avatarId}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.glassFillStrong,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 38, color: AppColors.textSecondary),
    );
  }
}
