import 'package:flutter/material.dart';
import '../../models/wallet_transaction_model.dart';
import '../../theme/app_theme.dart';

/// Derives a human title, icon and accent color for a transaction from
/// its real `type` / `reference_type` -- never invents a category the
/// backend doesn't support (see WalletTransactionType).
class TransactionMeta {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const TransactionMeta({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  factory TransactionMeta.of(WalletTransactionModel txn) {
    switch (txn.type) {
      case WalletTransactionType.credit:
        if (txn.referenceType == 'tournament_winning_payout') {
          return const TransactionMeta(
            title: 'Won Prize',
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.success,
            iconBg: Color(0xFF16321F),
          );
        }
        return const TransactionMeta(
          title: 'Added Money',
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.success,
          iconBg: Color(0xFF15321F),
        );
      case WalletTransactionType.bonus:
        return const TransactionMeta(
          title: 'Bonus Received',
          icon: Icons.card_giftcard_rounded,
          iconColor: AppColors.purpleSoft,
          iconBg: Color(0xFF2A2050),
        );
      case WalletTransactionType.refund:
        return const TransactionMeta(
          title: 'Refund',
          icon: Icons.replay_rounded,
          iconColor: AppColors.success,
          iconBg: Color(0xFF15321F),
        );
      case WalletTransactionType.releaseHold:
        return const TransactionMeta(
          title: 'Hold Released',
          icon: Icons.lock_open_rounded,
          iconColor: AppColors.success,
          iconBg: Color(0xFF15321F),
        );
      case WalletTransactionType.hold:
        return const TransactionMeta(
          title: 'Funds Held',
          icon: Icons.lock_clock_rounded,
          iconColor: AppColors.gold,
          iconBg: Color(0xFF3A2A0E),
        );
      case WalletTransactionType.debit:
        if (txn.referenceType == 'withdrawal_request') {
          return const TransactionMeta(
            title: 'Withdrawal',
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.live,
            iconBg: Color(0xFF3A1414),
          );
        }
        return const TransactionMeta(
          title: 'Tournament Joined',
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.gold,
          iconBg: Color(0xFF3A2A0E),
        );
      case WalletTransactionType.adminAdjustment:
        return const TransactionMeta(
          title: 'Wallet Adjustment',
          icon: Icons.tune_rounded,
          iconColor: AppColors.textSecondary,
          iconBg: Color(0xFF23222E),
        );
    }
  }
}

String statusLabel(WalletTransactionStatus status, bool isInflow) {
  switch (status) {
    case WalletTransactionStatus.success:
      return isInflow ? 'Credited' : 'Debited';
    case WalletTransactionStatus.pending:
      return 'Pending';
    case WalletTransactionStatus.failed:
      return 'Failed';
    case WalletTransactionStatus.cancelled:
      return 'Cancelled';
  }
}

Color statusColor(WalletTransactionStatus status, bool isInflow) {
  switch (status) {
    case WalletTransactionStatus.success:
      return isInflow ? AppColors.success : AppColors.live;
    case WalletTransactionStatus.pending:
      return AppColors.gold;
    case WalletTransactionStatus.failed:
      return AppColors.live;
    case WalletTransactionStatus.cancelled:
      return AppColors.textMuted;
  }
}

/// Human-readable reference-type label used as the subtitle line, e.g.
/// "payment_deposit" -> "UPI Deposit". Falls back to a title-cased
/// version of the raw reference_type so nothing is ever invented.
String referenceLabel(String? referenceType) {
  switch (referenceType) {
    case 'payment_deposit':
      return 'UPI Deposit';
    case 'tournament_winning_payout':
      return 'Prize Payout';
    case 'withdrawal_request':
      return 'Withdrawal';
    case 'tournament_entry':
    case 'tournament_slot_entry_fee':
      return 'Tournament Entry';
    case 'tournament_entry_refund':
      return 'Entry Fee Refund';
    case 'team_tournament_entry_fee':
      return 'Team Entry';
    case 'prize_payout':
      return 'Prize Payout';
    case null:
      return 'Wallet';
    default:
      return referenceType
          .split('_')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
  }
}
