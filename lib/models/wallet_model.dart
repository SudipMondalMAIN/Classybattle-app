/// Mirrors app/schemas/wallet.py -> WalletReadWithTotal on the backend.
class WalletModel {
  final double depositBalance;
  final double winningsBalance;
  final double availableBalance;
  final double lockedBalance;
  final double totalBalance;
  final String currency;
  final bool isFrozen;

  WalletModel({
    required this.depositBalance,
    required this.winningsBalance,
    required this.availableBalance,
    required this.lockedBalance,
    required this.totalBalance,
    required this.currency,
    required this.isFrozen,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      depositBalance: double.tryParse('${json['deposit_balance']}') ?? 0,
      winningsBalance: double.tryParse('${json['winnings_balance']}') ?? 0,
      availableBalance: double.tryParse('${json['available_balance']}') ?? 0,
      lockedBalance: double.tryParse('${json['locked_balance']}') ?? 0,
      totalBalance: double.tryParse('${json['total_balance']}') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      isFrozen: json['is_frozen'] as bool? ?? false,
    );
  }
}
