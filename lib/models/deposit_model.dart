/// Mirrors app/schemas/payment.py -> DepositQRResponse.
class DepositQrModel {
  final String upiId;
  final String merchantName;
  final double amount;
  final String currency;
  final String? note;
  final String qrPayload;

  DepositQrModel({
    required this.upiId,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.note,
    required this.qrPayload,
  });

  factory DepositQrModel.fromJson(Map<String, dynamic> json) {
    return DepositQrModel(
      upiId: json['upi_id'] as String? ?? '',
      merchantName: json['merchant_name'] as String? ?? '',
      amount: double.tryParse('${json['amount']}') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      note: json['note'] as String?,
      qrPayload: json['qr_payload'] as String? ?? '',
    );
  }
}

/// Mirrors app/schemas/payment.py -> PaymentSettingsRead (only the
/// fields a depositing user needs).
class PaymentSettingsModel {
  final bool isUpiEnabled;
  final double minDepositAmount;
  final double maxDepositAmount;

  PaymentSettingsModel({
    required this.isUpiEnabled,
    required this.minDepositAmount,
    required this.maxDepositAmount,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return PaymentSettingsModel(
      isUpiEnabled: json['is_upi_enabled'] as bool? ?? true,
      minDepositAmount: double.tryParse('${json['min_deposit_amount']}') ?? 0,
      maxDepositAmount: double.tryParse('${json['max_deposit_amount']}') ?? 0,
    );
  }
}
