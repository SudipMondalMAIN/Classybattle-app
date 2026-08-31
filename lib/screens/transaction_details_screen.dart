import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../models/wallet_transaction_detail_model.dart';
import '../models/wallet_transaction_model.dart';
import '../providers/wallet_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/wallet/transaction_meta.dart';

/// Full detail view for one transaction -- opened by tapping a row in
/// [TransactionsScreen] or the Wallet screen's Recent Transactions list.
///
/// [initial] is the row's already-fetched WalletTransactionModel, so the
/// screen can paint everything it can from that immediately (no spinner
/// for the common fields). It then fetches the richer
/// WalletTransactionDetailModel (balance-after breakdown) from
/// GET /wallet/transactions/{id} in the background and fills that part
/// in once it lands.
class TransactionDetailsScreen extends ConsumerWidget {
  const TransactionDetailsScreen({super.key, required this.initial});

  final WalletTransactionModel initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(transactionDetailProvider(initial.id));
    final meta = TransactionMeta.of(initial);
    final inflow = initial.isInflow;
    final amountColor = inflow ? AppColors.success : AppColors.live;
    final sign = inflow ? '+' : '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientTop,
              AppColors.backgroundGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Transaction Details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- hero: icon, title, amount, status ----
                      GlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: meta.iconBg,
                              ),
                              child: Icon(
                                meta.icon,
                                size: 26,
                                color: meta.iconColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              meta.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$sign${formatRupees(initial.amount)}',
                              style: TextStyle(
                                color: amountColor,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(
                                  initial.status,
                                  inflow,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor(
                                    initial.status,
                                    inflow,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                statusLabel(initial.status, inflow),
                                style: TextStyle(
                                  color: statusColor(initial.status, inflow),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- basic info (always available instantly) ----
                      _SectionCard(
                        children: [
                          _InfoRow(
                            label: 'Date & Time',
                            value: formatIstDateTime(initial.createdAt),
                          ),
                          _InfoRow(
                            label: 'Category',
                            value: referenceLabel(initial.referenceType),
                          ),
                          if (initial.txnNo != null &&
                              initial.txnNo!.isNotEmpty)
                            _InfoRow(
                              label: 'Transaction ID',
                              value: initial.txnNo!,
                              copyable: true,
                            ),
                          if (initial.description != null &&
                              initial.description!.trim().isNotEmpty)
                            _InfoRow(
                              label: 'Note',
                              value: initial.description!,
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ---- balance breakdown (fetched detail) ----
                      detailAsync.when(
                        loading: () => const _SectionCard(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.purpleSoft,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        error: (_, __) => const _SectionCard(
                          children: [
                            Text(
                              "Couldn't load balance breakdown.",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        data: (d) => _BalanceBreakdown(detail: d),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceBreakdown extends StatelessWidget {
  const _BalanceBreakdown({required this.detail});

  final WalletTransactionDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final hasDeltas = detail.depositDelta != 0 || detail.winningsDelta != 0;
    return _SectionCard(
      title: 'Balance After This Transaction',
      children: [
        _InfoRow(
          label: 'Available Balance',
          value: formatRupees(detail.availableBalanceAfter),
          highlight: true,
        ),
        _InfoRow(
          label: 'Deposit Balance',
          value: formatRupees(detail.depositBalanceAfter),
        ),
        _InfoRow(
          label: 'Winnings Balance',
          value: formatRupees(detail.winningsBalanceAfter),
        ),
        if (detail.lockedBalanceAfter != 0)
          _InfoRow(
            label: 'Locked (On Hold)',
            value: formatRupees(detail.lockedBalanceAfter),
          ),
        if (hasDeltas) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.glassBorder, height: 1),
          ),
          if (detail.depositDelta != 0)
            _InfoRow(
              label: 'Deposit Change',
              value:
                  '${detail.depositDelta > 0 ? '+' : ''}${formatRupees(detail.depositDelta)}',
            ),
          if (detail.winningsDelta != 0)
            _InfoRow(
              label: 'Winnings Change',
              value:
                  '${detail.winningsDelta > 0 ? '+' : ''}${formatRupees(detail.winningsDelta)}',
            ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: highlight
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          if (copyable) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(
                Icons.copy_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
