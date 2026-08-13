import 'payment_method_model.dart';

/// Mirrors app/models/withdrawal.py -> WithdrawalStatus.
enum WithdrawalStatus {
  pending,
  completed,
  cancelled;

  static WithdrawalStatus fromJson(String raw) {
    switch (raw) {
      case 'pending':
        return WithdrawalStatus.pending;
      case 'completed':
        return WithdrawalStatus.completed;
      case 'cancelled':
        return WithdrawalStatus.cancelled;
      default:
        return WithdrawalStatus.pending;
    }
  }
}

/// Mirrors app/schemas/withdrawal.py -> WithdrawalRequestRead.
class WithdrawalModel {
  final String id;
  final int shortId;
  final String txnNo;
  final double amount;
  final String currency;
  final PaymentMethodType methodType;
  final WithdrawalStatus status;
  final DateTime createdAt;

  WithdrawalModel({
    required this.id,
    required this.shortId,
    required this.txnNo,
    required this.amount,
    required this.currency,
    required this.methodType,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'] as String,
      shortId: (json['short_id'] as num?)?.toInt() ?? 0,
      txnNo: json['txn_no'] as String? ?? '',
      amount: double.tryParse('${json['amount']}') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      methodType: PaymentMethodType.fromJson(json['method_type'] as String? ?? ''),
      status: WithdrawalStatus.fromJson(json['status'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
