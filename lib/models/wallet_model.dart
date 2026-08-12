/// Mirrors app/schemas/wallet.py -> WalletReadWithTotal on the backend.
class WalletModel {
  final double availableBalance;
  final double lockedBalance;
  final double totalBalance;
  final String currency;
  final bool isFrozen;

  WalletModel({
    required this.availableBalance,
    required this.lockedBalance,
    required this.totalBalance,
    required this.currency,
    required this.isFrozen,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      availableBalance: double.tryParse('${json['available_balance']}') ?? 0,
      lockedBalance: double.tryParse('${json['locked_balance']}') ?? 0,
      totalBalance: double.tryParse('${json['total_balance']}') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      isFrozen: json['is_frozen'] as bool? ?? false,
    );
  }
}
