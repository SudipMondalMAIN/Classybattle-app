import 'wallet_transaction_model.dart';

/// Mirrors app/schemas/wallet.py -> WalletTransactionRead. Adds the
/// balance-breakdown fields (deposit/winnings deltas + all four
/// after-balances) that the list endpoint's WalletTransactionModel
/// doesn't carry -- these only matter on the single-transaction detail
/// view, not the scrolling list.
class WalletTransactionDetailModel {
  final String id;
  final WalletTransactionType type;
  final WalletTransactionStatus status;
  final double amount;
  final String currency;
  final String balanceSource;
  final double depositDelta;
  final double winningsDelta;
  final double depositBalanceAfter;
  final double winningsBalanceAfter;
  final double availableBalanceAfter;
  final double lockedBalanceAfter;
  final String? description;
  final String? referenceType;
  final String? referenceId;
  final String? relatedTransactionId;
  final DateTime createdAt;
  final String? txnNo;

  WalletTransactionDetailModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.balanceSource,
    required this.depositDelta,
    required this.winningsDelta,
    required this.depositBalanceAfter,
    required this.winningsBalanceAfter,
    required this.availableBalanceAfter,
    required this.lockedBalanceAfter,
    required this.description,
    required this.referenceType,
    required this.referenceId,
    required this.relatedTransactionId,
    required this.createdAt,
    this.txnNo,
  });

  factory WalletTransactionDetailModel.fromJson(Map<String, dynamic> json) {
    double num_(dynamic v) => double.tryParse('$v') ?? 0;
    return WalletTransactionDetailModel(
      id: json['id'] as String,
      type: WalletTransactionType.fromJson(json['type'] as String? ?? ''),
      status: WalletTransactionStatus.fromJson(
        json['status'] as String? ?? '',
      ),
      amount: num_(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      balanceSource: json['balance_source'] as String? ?? '',
      depositDelta: num_(json['deposit_delta']),
      winningsDelta: num_(json['winnings_delta']),
      depositBalanceAfter: num_(json['deposit_balance_after']),
      winningsBalanceAfter: num_(json['winnings_balance_after']),
      availableBalanceAfter: num_(json['available_balance_after']),
      lockedBalanceAfter: num_(json['locked_balance_after']),
      description: json['description'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      relatedTransactionId: json['related_transaction_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      txnNo: json['txn_no'] as String?,
    );
  }

  bool get isInflow {
    switch (type) {
      case WalletTransactionType.credit:
      case WalletTransactionType.refund:
      case WalletTransactionType.bonus:
      case WalletTransactionType.releaseHold:
        return true;
      case WalletTransactionType.debit:
      case WalletTransactionType.hold:
      case WalletTransactionType.adminAdjustment:
        return false;
    }
  }
}
