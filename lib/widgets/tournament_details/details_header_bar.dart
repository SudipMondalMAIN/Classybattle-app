import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class DetailsHeaderBar extends ConsumerWidget {
  const DetailsHeaderBar({super.key, required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final user = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tournament Details',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                  error: (_, __) =>
                      const Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.add_circle, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onNotificationsTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.notifications_none_rounded,
                      size: 20, color: AppColors.textPrimary),
                ),
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
          ),
          const SizedBox(width: 10),
          user.when(
            data: (u) => CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.glassFillStrong,
              backgroundImage:
                  u?.avatarId != null ? AssetImage('assets/avatars/${u!.avatarId}.png') : null,
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
          ),
        ],
      ),
    );
  }
}
