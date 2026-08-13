import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class HeaderBar extends ConsumerWidget {
  const HeaderBar({
    super.key,
    required this.onNotificationsTap,
    required this.onWalletTap,
    required this.onProfileTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onWalletTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final user = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/cb_logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: 'Classy'),
                TextSpan(text: 'Battle', style: TextStyle(color: AppColors.purple)),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onWalletTap,
            child: _WalletChip(wallet: wallet),
          ),
          const SizedBox(width: 10),
          _IconButtonGlass(
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationsTap,
            showDot: true,
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfileTap,
            child: _AvatarButton(user: user),
          ),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.wallet});

  final AsyncValue wallet;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          wallet.when(
            data: (w) => Text(
              w == null ? 'Login' : formatRupees(w.availableBalance),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            loading: () => const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text(
              '—',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.add_circle, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _IconButtonGlass extends StatelessWidget {
  const _IconButtonGlass({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          if (showDot)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.user});

  final AsyncValue user;

  @override
  Widget build(BuildContext context) {
    return user.when(
      data: (u) => CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.glassFillStrong,
        // Bundled avatar assets (assets/avatars/avatar_N.png) aren't in
        // this repo yet -- once added + declared in pubspec.yaml this
        // will pick them up automatically. Falls back to a plain icon
        // if the asset is missing, instead of crashing.
        backgroundImage: u?.avatarId != null
            ? AssetImage('assets/avatars/${u!.avatarId}.png')
            : null,
        onBackgroundImageError: u?.avatarId != null ? (_, __) {} : null,
        child: u?.avatarId == null
            ? const Icon(Icons.person, size: 18, color: AppColors.textSecondary)
            : null,
      ),
      loading: () => const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.glassFillStrong,
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.glassFillStrong,
        child: Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
