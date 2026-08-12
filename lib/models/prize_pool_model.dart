/// Mirrors app/schemas/prize.py -> PrizePoolRead on the backend.
/// distribution_rules entries are either percentage-based or a fixed
/// amount per rank -- [payoutForRank] resolves either shape to a real
/// rupee amount so the UI never has to guess.
class PrizePoolRank {
  final int rank;
  final double? percentage;
  final double? amount;

  PrizePoolRank({required this.rank, this.percentage, this.amount});

  factory PrizePoolRank.fromJson(Map<String, dynamic> json) {
    return PrizePoolRank(
      rank: (json['rank'] as num).toInt(),
      percentage: json['percentage'] == null
          ? null
          : double.tryParse('${json['percentage']}'),
      amount: json['amount'] == null
          ? null
          : double.tryParse('${json['amount']}'),
    );
  }
}

class PrizePoolModel {
  final String id;
  final String tournamentId;
  final double totalAmount;
  final String distributionType; // single_winner | top_n | percentage | fixed_amount
  final List<PrizePoolRank> rules;
  final String status;

  PrizePoolModel({
    required this.id,
    required this.tournamentId,
    required this.totalAmount,
    required this.distributionType,
    required this.rules,
    required this.status,
  });

  /// Real payout amount for a given rank, derived from the pool's
  /// actual rule for that rank (never a screenshot placeholder).
  double payoutForRank(int rank) {
    final rule = rules.where((r) => r.rank == rank).firstOrNull;
    if (rule == null) return 0;
    if (rule.amount != null) return rule.amount!;
    if (rule.percentage != null) return totalAmount * rule.percentage! / 100;
    return 0;
  }

  List<int> get ranks => rules.map((r) => r.rank).toList()..sort();

  factory PrizePoolModel.fromJson(Map<String, dynamic> json) {
    final rulesJson = json['distribution_rules'] as List? ?? const [];
    return PrizePoolModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      totalAmount: double.tryParse('${json['total_amount']}') ?? 0,
      distributionType: json['distribution_type'] as String? ?? '',
      rules: rulesJson
          .map((e) => PrizePoolRank.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? '',
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
