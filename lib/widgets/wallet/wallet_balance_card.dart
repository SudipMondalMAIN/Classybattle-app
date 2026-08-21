import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../models/wallet_model.dart';
import '../../providers/wallet_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import 'wallet_artwork.dart';

class WalletBalanceCard extends ConsumerWidget {
  const WalletBalanceCard({
    super.key,
    required this.wallet,
    required this.onAddMoney,
    required this.onWithdraw,
  });

  final WalletModel? wallet;
  final VoidCallback onAddMoney;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(walletBalanceVisibleProvider);
    final balanceText = wallet == null
        ? '₹ —'
        : (visible ? formatRupees(wallet!.totalBalance) : '₹ •••••');
    final depositText = wallet == null
        ? '₹ —'
        : (visible ? formatRupees(wallet!.depositBalance) : '₹ •••••');
    final winningsText = wallet == null
        ? '₹ —'
        : (visible ? formatRupees(wallet!.winningsBalance) : '₹ •••••');

    return GlassContainer(
      borderRadius: 24,
      glow: true,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            balanceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            final notifier =
                                ref.read(walletBalanceVisibleProvider.notifier);
                            notifier.state = !notifier.state;
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Icon(
                              visible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            wallet?.isFrozen == true ? 'Wallet Frozen' : 'Secure Wallet',
                            style: TextStyle(
                              color: wallet?.isFrozen == true
                                  ? AppColors.live
                                  : AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const WalletArtwork(size: 108),
            ],
          ),
          const SizedBox(height: 20),
          // Deposit balance (usable only for tournament entry) + Add Money.
          _BalanceRow(
            label: 'Deposit Balance',
            valueText: depositText,
            dotColor: AppColors.success,
            button: _AddMoneyButton(onTap: onAddMoney),
          ),
          const SizedBox(height: 12),
          // Winnings balance (usable for entry + withdrawal) + Withdraw.
          _BalanceRow(
            label: 'Winnings Balance',
            valueText: winningsText,
            dotColor: AppColors.gold,
            button: _WithdrawButton(onTap: onWithdraw),
          ),
        ],
      ),
    );
  }
}

/// One balance figure paired with its own action button, e.g.
/// "Deposit Balance ₹500" next to "Add Money", or
/// "Winnings Balance ₹1,200" next to "Withdraw".
class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.valueText,
    required this.dotColor,
    required this.button,
  });

  final String label;
  final String valueText;
  final Color dotColor;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 118, child: button),
        ],
      ),
    );
  }
}

class _AddMoneyButton extends StatelessWidget {
  const _AddMoneyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.purpleButton,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 17, color: Colors.white),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Add Money',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorderBright, width: 1.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_rounded, size: 16, color: AppColors.purpleSoft),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Withdraw',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.purpleSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
