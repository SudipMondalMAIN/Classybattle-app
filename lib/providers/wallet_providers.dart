import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_transaction_model.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/wallet_service.dart';

/// The 4 most recent transactions for the Recent Transactions section.
/// Empty (not error) when signed out, matching walletProvider's
/// "no fake data, just nothing to show" behaviour.
final recentTransactionsProvider = FutureProvider<List<WalletTransactionModel>>((
  ref,
) async {
  try {
    final result = await walletService.fetchTransactions(page: 1, pageSize: 4);
    return result.items;
  } on UnauthenticatedException {
    return [];
  }
});

/// Total Added / Total Used / Winning / Bonus, derived from the real
/// transaction ledger (see WalletService.fetchSummary).
final walletSummaryProvider = FutureProvider<WalletSummary?>((ref) async {
  try {
    return await walletService.fetchSummary();
  } on UnauthenticatedException {
    return null;
  }
});

/// One page of the full transaction history, for the "View All" screen.
final transactionsPageProvider =
    FutureProvider.family<PagedTransactions, int>((ref, page) async {
  try {
    return await walletService.fetchTransactions(page: page, pageSize: 20);
  } on UnauthenticatedException {
    return PagedTransactions(const [], 0, 0);
  }
});

/// Whether the balance figures should currently be masked ("•••••").
/// Screen-local UI state, shared here so it survives widget rebuilds
/// while the Wallet Screen is on screen.
final walletBalanceVisibleProvider = StateProvider<bool>((ref) => true);
