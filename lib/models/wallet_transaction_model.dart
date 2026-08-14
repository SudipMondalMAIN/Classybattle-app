/// Mirrors app/models/wallet_transaction.py enums exactly (lowercase
/// string values on the wire).
enum WalletTransactionType {
  credit,
  debit,
  hold,
  releaseHold,
  refund,
  bonus,
  adminAdjustment;

  static WalletTransactionType fromJson(String raw) {
    switch (raw) {
      case 'credit':
        return WalletTransactionType.credit;
      case 'debit':
        return WalletTransactionType.debit;
      case 'hold':
        return WalletTransactionType.hold;
      case 'release_hold':
        return WalletTransactionType.releaseHold;
      case 'refund':
        return WalletTransactionType.refund;
      case 'bonus':
        return WalletTransactionType.bonus;
      case 'admin_adjustment':
        return WalletTransactionType.adminAdjustment;
      default:
        return WalletTransactionType.adminAdjustment;
    }
  }

  String toJson() {
    switch (this) {
      case WalletTransactionType.credit:
        return 'credit';
      case WalletTransactionType.debit:
        return 'debit';
      case WalletTransactionType.hold:
        return 'hold';
      case WalletTransactionType.releaseHold:
        return 'release_hold';
      case WalletTransactionType.refund:
        return 'refund';
      case WalletTransactionType.bonus:
        return 'bonus';
      case WalletTransactionType.adminAdjustment:
        return 'admin_adjustment';
    }
  }
}

enum WalletTransactionStatus {
  pending,
  success,
  failed,
  cancelled;

  static WalletTransactionStatus fromJson(String raw) {
    switch (raw) {
      case 'pending':
        return WalletTransactionStatus.pending;
      case 'success':
        return WalletTransactionStatus.success;
      case 'failed':
        return WalletTransactionStatus.failed;
      case 'cancelled':
        return WalletTransactionStatus.cancelled;
      default:
        return WalletTransactionStatus.pending;
    }
  }
}

/// Mirrors app/schemas/wallet.py -> WalletTransactionRead.
class WalletTransactionModel {
  final String id;
  final WalletTransactionType type;
  final WalletTransactionStatus status;
  final double amount;
  final String currency;
  final String? description;
  final String? referenceType;
  final String? referenceId;
  final DateTime createdAt;
  // Human-facing 10-digit transaction number for deposits/withdrawals
  // only (reference_type payment_deposit / withdrawal_request). Null
  // for every other transaction type.
  final String? txnNo;

  WalletTransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
    this.txnNo,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      type: WalletTransactionType.fromJson(json['type'] as String? ?? ''),
      status: WalletTransactionStatus.fromJson(json['status'] as String? ?? ''),
      amount: double.tryParse('${json['amount']}') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      description: json['description'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      txnNo: json['txn_no'] as String?,
    );
  }

  /// Whether this row reads as money coming in (+) vs going out (-).
  /// HOLD/ADMIN_ADJUSTMENT amounts are always non-negative on the wire
  /// (DB check constraint) and are shown as an outflow by default,
  /// which matches the common case (funds set aside / manual debit).
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
