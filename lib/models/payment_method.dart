/// Mirrors app/models/payment_method.py -> PaymentMethodType.
enum PaymentMethodType { upi, bankAccount }

extension PaymentMethodTypeX on PaymentMethodType {
  String get wire => this == PaymentMethodType.upi ? 'upi' : 'bank_account';

  static PaymentMethodType fromWire(String v) {
    switch (v) {
      case 'upi':
        return PaymentMethodType.upi;
      case 'bank_account':
        return PaymentMethodType.bankAccount;
      default:
        return PaymentMethodType.upi;
    }
  }
}

/// Mirrors app/schemas/payment_method.py -> PaymentMethodRead.
class PaymentMethod {
  final String id;
  final PaymentMethodType methodType;
  final String accountHolderName;
  final String? upiId;
  final String? accountNumber;
  final String? ifscCode;
  final bool isActive;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.methodType,
    required this.accountHolderName,
    this.upiId,
    this.accountNumber,
    this.ifscCode,
    required this.isActive,
    required this.createdAt,
  });

  String get displayLabel {
    if (methodType == PaymentMethodType.upi) return upiId ?? 'UPI';
    final acc = accountNumber ?? '';
    final masked = acc.length > 4 ? '••••${acc.substring(acc.length - 4)}' : acc;
    return '$masked${ifscCode != null ? ' · $ifscCode' : ''}';
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      methodType: PaymentMethodTypeX.fromWire(json['method_type'] as String),
      accountHolderName: json['account_holder_name'] as String,
      upiId: json['upi_id'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
