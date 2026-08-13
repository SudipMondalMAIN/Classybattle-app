/// Mirrors app/models/payment_method.py enums exactly (lowercase
/// string values on the wire).
enum PaymentMethodType {
  upi,
  bank;

  static PaymentMethodType fromJson(String raw) {
    switch (raw) {
      case 'upi':
        return PaymentMethodType.upi;
      case 'bank':
        return PaymentMethodType.bank;
      default:
        return PaymentMethodType.upi;
    }
  }

  String toJson() {
    switch (this) {
      case PaymentMethodType.upi:
        return 'upi';
      case PaymentMethodType.bank:
        return 'bank';
    }
  }
}

/// Mirrors app/schemas/payment_method.py -> PaymentMethodRead.
class PaymentMethodModel {
  final String id;
  final PaymentMethodType methodType;
  final String accountHolderName;
  final String? upiId;
  final String? accountNumber;
  final String? ifscCode;
  final bool isActive;

  PaymentMethodModel({
    required this.id,
    required this.methodType,
    required this.accountHolderName,
    required this.upiId,
    required this.accountNumber,
    required this.ifscCode,
    required this.isActive,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      methodType: PaymentMethodType.fromJson(json['method_type'] as String? ?? ''),
      accountHolderName: json['account_holder_name'] as String? ?? '',
      upiId: json['upi_id'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String get subtitle =>
      methodType == PaymentMethodType.upi ? (upiId ?? '') : '${ifscCode ?? ''} · ${accountNumber ?? ''}';
}
