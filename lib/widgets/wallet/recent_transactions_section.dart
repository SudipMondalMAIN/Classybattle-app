import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wallet_transaction_model.dart';
import '../../theme/app_theme.dart';
import 'transaction_row.dart';

/// Pinned "Recent Transactions" title + "View All" row. Kept separate
/// from [RecentTransactionsList] so callers can hold this fixed on
/// screen while only the list below it scrolls.
class RecentTransactionsHeader extends StatelessWidget {
  const RecentTransactionsHeader({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.purpleSoft),
            ],
          ),
        ),
      ],
    );
  }
}

/// The transaction rows themselves (loading/error/empty/data states),
/// with no heading -- meant to sit inside a scrollable area below a
/// pinned [RecentTransactionsHeader].
class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({
    super.key,
    required this.async,
    required this.onRetry,
    this.onTapTransaction,
  });

  final AsyncValue<List<WalletTransactionModel>> async;
  final VoidCallback onRetry;
  final void Function(WalletTransactionModel txn)? onTapTransaction;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleSoft),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Text(
              "Couldn't load your transactions.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purpleSoft,
                side: const BorderSide(color: AppColors.glassBorder),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++)
              TransactionRow(
                txn: items[i],
                showDivider: i != items.length - 1,
                onTap: onTapTransaction == null
                    ? null
                    : () => onTapTransaction!(items[i]),
              ),
          ],
        );
      },
    );
  }
}
