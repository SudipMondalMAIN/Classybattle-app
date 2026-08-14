import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/wallet_transaction_model.dart';
import '../../theme/app_theme.dart';
import 'transaction_meta.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.txn,
    this.onTap,
    this.showDivider = true,
  });

  final WalletTransactionModel txn;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final meta = TransactionMeta.of(txn);
    final inflow = txn.isInflow;
    final amountColor = inflow ? AppColors.success : AppColors.live;
    final sign = inflow ? '+' : '-';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.glassBorder, width: 1),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meta.iconBg,
              ),
              child: Icon(meta.icon, size: 20, color: meta.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${referenceLabel(txn.referenceType)} • ${formatIstDateTime(txn.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  // Only deposits/withdrawals carry a txn_no from the
                  // backend — everything else (tournament entry, prize
                  // payout, etc.) leaves this null and nothing renders.
                  if (txn.txnNo != null && txn.txnNo!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'TXN ID: ${txn.txnNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${formatRupees(txn.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel(txn.status, inflow),
                  style: TextStyle(
                    color: statusColor(txn.status, inflow),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
