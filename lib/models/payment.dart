/// Mirrors app/schemas/payment.py -> PaymentSettingsRead (the subset a
/// depositing user needs from GET /payments/settings).
class PaymentSettings {
  final String? upiId;
  final String merchantName;
  final String? paymentNote;
  final bool isUpiEnabled;
  final double minDepositAmount;
  final double maxDepositAmount;

  PaymentSettings({
    this.upiId,
    required this.merchantName,
    this.paymentNote,
    required this.isUpiEnabled,
    required this.minDepositAmount,
    required this.maxDepositAmount,
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    return PaymentSettings(
      upiId: json['upi_id'] as String?,
      merchantName: json['merchant_name'] as String,
      paymentNote: json['payment_note'] as String?,
      isUpiEnabled: json['is_upi_enabled'] as bool? ?? true,
      minDepositAmount: double.tryParse(json['min_deposit_amount'].toString()) ?? 0,
      maxDepositAmount: double.tryParse(json['max_deposit_amount'].toString()) ?? 0,
    );
  }
}

/// Mirrors app/schemas/payment.py -> DepositQRResponse.
class DepositQuote {
  final String upiId;
  final String merchantName;
  final double amount;
  final String currency;
  final String? note;
  final String qrPayload;

  DepositQuote({
    required this.upiId,
    required this.merchantName,
    required this.amount,
    required this.currency,
    this.note,
    required this.qrPayload,
  });

  factory DepositQuote.fromJson(Map<String, dynamic> json) {
    return DepositQuote(
      upiId: json['upi_id'] as String,
      merchantName: json['merchant_name'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      note: json['note'] as String?,
      qrPayload: json['qr_payload'] as String,
    );
  }
}

/// Mirrors app/schemas/payment.py -> PaymentRequestRead.
class PaymentRequest {
  final String id;
  final int shortId;
  final String txnNo;
  final double amount;
  final String currency;
  final String screenshotUrl;
  final String? utrNumber;
  final String status; // PaymentRequestStatus: pending/on_hold/approved/rejected/cancelled
  final DateTime submittedAt;
  final String? rejectionNote;

  PaymentRequest({
    required this.id,
    required this.shortId,
    required this.txnNo,
    required this.amount,
    required this.currency,
    required this.screenshotUrl,
    this.utrNumber,
    required this.status,
    required this.submittedAt,
    this.rejectionNote,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as String,
      shortId: json['short_id'] as int,
      txnNo: json['txn_no'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      screenshotUrl: json['screenshot_url'] as String,
      utrNumber: json['utr_number'] as String?,
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      rejectionNote: json['rejection_note'] as String?,
    );
  }
}
