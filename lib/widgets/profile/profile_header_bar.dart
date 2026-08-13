import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class ProfileHeaderBar extends ConsumerWidget {
  const ProfileHeaderBar({
    super.key,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GlassContainer(
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
              ],
            ),
          ),
          const SizedBox(width: 10),
          _IconButtonGlass(
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 10),
          _IconButtonGlass(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _IconButtonGlass extends StatelessWidget {
  const _IconButtonGlass({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(9),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
