/// Mirrors app/schemas/wallet.py -> WalletReadWithTotal / WalletTransactionRead.
class Wallet {
  final double availableBalance;
  final double lockedBalance;
  final double totalBalance;
  final String currency;
  final bool isFrozen;

  Wallet({
    required this.availableBalance,
    required this.lockedBalance,
    required this.totalBalance,
    required this.currency,
    required this.isFrozen,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      availableBalance: double.tryParse(json['available_balance'].toString()) ?? 0,
      lockedBalance: double.tryParse(json['locked_balance'].toString()) ?? 0,
      totalBalance: double.tryParse(json['total_balance'].toString()) ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      isFrozen: json['is_frozen'] as bool? ?? false,
    );
  }
}

class WalletTransaction {
  final String id;
  final String type; // credit | debit | hold | release | ...
  final String status;
  final double amount;
  final String? description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
