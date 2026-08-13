import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/wallet_transaction_model.dart';
import 'home_service.dart' show UnauthenticatedException;

class PagedTransactions {
  PagedTransactions(this.items, this.total, this.totalPages);
  final List<WalletTransactionModel> items;
  final int total;
  final int totalPages;
}

/// Real, backend-derived roll-up numbers for the Wallet Summary cards.
/// There is no dedicated "/wallet/summary" endpoint on the backend, so
/// these are computed client-side from the user's real transaction
/// ledger (see [WalletService.fetchSummary]) -- never hardcoded.
class WalletSummary {
  const WalletSummary({
    required this.totalAdded,
    required this.totalUsed,
    required this.totalWinnings,
    required this.totalBonus,
  });

  final double totalAdded;
  final double totalUsed;
  final double totalWinnings;
  final double totalBonus;
}

class WalletService {
  WalletService(this._dio);

  final Dio _dio;

  /// GET /wallet/transactions -- paginated ledger for the current user.
  Future<PagedTransactions> fetchTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/wallet/transactions',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'sort_by': 'created_at',
          'sort_order': 'desc',
        },
      );
      final items = (res.data['items'] as List)
          .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (res.data['total'] as num?)?.toInt() ?? items.length;
      final totalPages = (res.data['total_pages'] as num?)?.toInt() ?? 1;
      return PagedTransactions(items, total, totalPages);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// Builds Total Added / Total Used / Winning / Bonus from the real
  /// ledger. The backend has no aggregate endpoint for this, so we walk
  /// the user's own successful transactions and sum by type. Capped at
  /// [maxPages] pages (default 2,000 rows) as a safety limit for very
  /// long-lived accounts -- everything summed is still real data, just
  /// possibly not the *entire* lifetime history for extreme edge cases.
  Future<WalletSummary> fetchSummary({int maxPages = 20}) async {
    double added = 0, used = 0, winnings = 0, bonus = 0;
    var page = 1;
    var totalPages = 1;
    do {
      final result = await fetchTransactions(page: page, pageSize: 100);
      totalPages = result.totalPages == 0 ? 1 : result.totalPages;
      for (final t in result.items) {
        if (t.status != WalletTransactionStatus.success) continue;
        switch (t.type) {
          case WalletTransactionType.credit:
            if (t.referenceType == 'tournament_winning_payout') {
              winnings += t.amount;
            } else {
              added += t.amount;
            }
            break;
          case WalletTransactionType.bonus:
            bonus += t.amount;
            break;
          case WalletTransactionType.debit:
            // "Used" tracks spend (tournament entries), not withdrawals
            // -- withdrawal has its own dedicated button/flow above.
            if (t.referenceType != 'withdrawal_request') {
              used += t.amount;
            }
            break;
          default:
            break;
        }
      }
      page++;
    } while (page <= totalPages && page <= maxPages);

    return WalletSummary(
      totalAdded: added,
      totalUsed: used,
      totalWinnings: winnings,
      totalBonus: bonus,
    );
  }
}

final walletService = WalletService(ApiClient.instance.dio);
