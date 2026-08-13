import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/wallet/transaction_row.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(transactionsPageProvider(_page));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGradientTop, AppColors.backgroundGradientBottom],
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
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'All Transactions',
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
                child: pageAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.purpleSoft),
                  ),
                  error: (_, __) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Couldn't load your transactions.",
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(transactionsPageProvider(_page)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.purpleSoft,
                            side: const BorderSide(color: AppColors.glassBorder),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (paged) {
                    if (paged.items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      );
                    }
                    final totalPages = paged.totalPages == 0 ? 1 : paged.totalPages;
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: paged.items.length,
                            itemBuilder: (context, i) => TransactionRow(
                              txn: paged.items[i],
                              showDivider: i != paged.items.length - 1,
                            ),
                          ),
                        ),
                        if (totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _page > 1
                                      ? () => setState(() => _page--)
                                      : null,
                                  icon: const Icon(Icons.chevron_left_rounded,
                                      color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Page $_page of $totalPages',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 13),
                                ),
                                IconButton(
                                  onPressed: _page < totalPages
                                      ? () => setState(() => _page++)
                                      : null,
                                  icon: const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
