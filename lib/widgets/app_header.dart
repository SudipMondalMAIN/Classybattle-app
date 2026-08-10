import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Top bar used across Tournaments / Tournament Details / Wallet (and other
/// inner) screens. Two modes:
///  - logo mode (home/tournaments root): brand mark + "ClassyBattle"
///  - back mode (detail/inner screens): back arrow + page title
class AppHeader extends StatelessWidget {
  final String? title; // used in back mode
  final bool showBack;
  final VoidCallback? onBack;
  final double walletBalance;
  final VoidCallback? onWallet;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final bool hasUnreadNotification;
  final bool showOnlineDot;

  const AppHeader({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
    this.walletBalance = 0,
    this.onWallet,
    this.onNotifications,
    this.onProfile,
    this.hasUnreadNotification = true,
    this.showOnlineDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          GestureDetector(
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24),
            ),
          ),
          Expanded(
            child: Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(4),
            child: ShaderMask(
              shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 6),
          const RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: 'Classy', style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(text: 'Battle', style: TextStyle(color: AppColors.purple)),
              ],
            ),
          ),
          const Spacer(),
        ],
        const SizedBox(width: 10),
        WalletChip(balance: walletBalance, onTap: onWallet),
        const SizedBox(width: 10),
        _IconBadgeButton(
          icon: Icons.notifications_none_rounded,
          showDot: hasUnreadNotification,
          onTap: onNotifications,
        ),
        const SizedBox(width: 10),
        _AvatarButton(showOnlineDot: showOnlineDot, onTap: onProfile),
      ],
    );
  }
}

class WalletChip extends StatelessWidget {
  final double balance;
  final VoidCallback? onTap;
  const WalletChip({super.key, required this.balance, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: AppColors.purple, size: 15),
            const SizedBox(width: 6),
            Text('₹${formatMoney(balance)}',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.add_circle_rounded, color: AppColors.purple, size: 16),
          ],
        ),
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;
  const _IconBadgeButton({required this.icon, this.showDot = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 24),
          if (showDot)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final bool showOnlineDot;
  final VoidCallback? onTap;
  const _AvatarButton({this.showOnlineDot = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          if (showOnlineDot)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgBottom, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
