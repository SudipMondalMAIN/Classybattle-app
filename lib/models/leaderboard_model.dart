/// Mirrors app/schemas/leaderboard.py -> PlayerStatisticsRead on the
/// backend. Returned by GET /leaderboard/players/top, already sorted
/// by rank.
class PlayerStatsModel {
  final String userId;
  final int matchesPlayed;
  final int matchesWon;
  final double winRate;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final double prizeMoneyEarned;
  final double rankingScore;
  final int? currentRank;
  final int? previousRank;

  PlayerStatsModel({
    required this.userId,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.winRate,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
    required this.prizeMoneyEarned,
    required this.rankingScore,
    this.currentRank,
    this.previousRank,
  });

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerStatsModel(
      userId: json['user_id'] as String,
      matchesPlayed: json['matches_played'] as int? ?? 0,
      matchesWon: json['matches_won'] as int? ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
      tournamentsPlayed: json['tournaments_played'] as int? ?? 0,
      tournamentsWon: json['tournaments_won'] as int? ?? 0,
      prizeMoneyEarned:
          double.tryParse(json['prize_money_earned']?.toString() ?? '') ?? 0,
      rankingScore:
          double.tryParse(json['ranking_score']?.toString() ?? '') ?? 0,
      currentRank: json['current_rank'] as int?,
      previousRank: json['previous_rank'] as int?,
    );
  }
}
