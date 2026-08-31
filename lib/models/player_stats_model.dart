/// Profile-screen "Tournaments Joined / Won / Total Winnings / Win Rate"
/// summary, from GET /users/me/stats.
///
/// Backed by PlayerStatistics on the backend, which both the admin
/// distribute-prizes flow AND the custom 1v1 pay_winner flow keep in
/// sync -- unlike the old /prize-payouts/me source, which only the
/// admin flow ever populated.
class PlayerStatsModel {
  const PlayerStatsModel({
    required this.joined,
    required this.won,
    required this.totalWinnings,
    required this.winRate,
  });

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerStatsModel(
      joined: (json['joined'] as num?)?.toInt() ?? 0,
      won: (json['won'] as num?)?.toInt() ?? 0,
      totalWinnings: (json['total_winnings'] as num?)?.toDouble() ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble(),
    );
  }

  final int joined;
  final int won;
  final double totalWinnings;
  final double? winRate;
}
