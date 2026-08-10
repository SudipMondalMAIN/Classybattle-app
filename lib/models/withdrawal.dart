import 'payment_method.dart';

/// Mirrors app/models/withdrawal.py -> WithdrawalStatus.
enum WithdrawalStatus { pending, completed, cancelled, rejected }

extension WithdrawalStatusX on WithdrawalStatus {
  String get wire {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'pending';
      case WithdrawalStatus.completed:
        return 'completed';
      case WithdrawalStatus.cancelled:
        return 'cancelled';
      case WithdrawalStatus.rejected:
        return 'rejected';
    }
  }

  static WithdrawalStatus fromWire(String v) {
    switch (v) {
      case 'pending':
        return WithdrawalStatus.pending;
      case 'completed':
        return WithdrawalStatus.completed;
      case 'cancelled':
        return WithdrawalStatus.cancelled;
      case 'rejected':
        return WithdrawalStatus.rejected;
      default:
        return WithdrawalStatus.pending;
    }
  }
}

/// Mirrors app/schemas/withdrawal.py -> WithdrawalRequestRead.
class WithdrawalRequest {
  final String id;
  final int shortId;
  final String txnNo;
  final double amount;
  final String currency;
  final PaymentMethodType methodType;
  final Map<String, dynamic> methodDetails;
  final WithdrawalStatus status;
  final String? adminNote;
  final DateTime? processedAt;
  final DateTime createdAt;

  WithdrawalRequest({
    required this.id,
    required this.shortId,
    required this.txnNo,
    required this.amount,
    required this.currency,
    required this.methodType,
    required this.methodDetails,
    required this.status,
    this.adminNote,
    this.processedAt,
    required this.createdAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String,
      shortId: json['short_id'] as int,
      txnNo: json['txn_no'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      methodType: PaymentMethodTypeX.fromWire(json['method_type'] as String),
      methodDetails: Map<String, dynamic>.from(json['method_details'] as Map? ?? {}),
      status: WithdrawalStatusX.fromWire(json['status'] as String),
      adminNote: json['admin_note'] as String?,
      processedAt: json['processed_at'] != null ? DateTime.tryParse(json['processed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
