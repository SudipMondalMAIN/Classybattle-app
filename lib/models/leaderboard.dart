/// Mirrors app/schemas/leaderboard.py -> PlayerStatisticsRead in the FastAPI backend.
class PlayerStatistics {
  final String id;
  final String userId;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final double winRate;
  final int kills;
  final int deaths;
  final double kdRatio;
  final int assists;
  final int mvpCount;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final double prizeMoneyEarned;
  final double walletEarnings;
  final double rankingScore;
  final int? currentRank;
  final int? previousRank;

  PlayerStatistics({
    required this.id,
    required this.userId,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.winRate,
    required this.kills,
    required this.deaths,
    required this.kdRatio,
    required this.assists,
    required this.mvpCount,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
    required this.prizeMoneyEarned,
    required this.walletEarnings,
    required this.rankingScore,
    this.currentRank,
    this.previousRank,
  });

  /// Used when the backend has no stats row yet for a brand-new player
  /// (returns 404 until they finish their first tournament).
  factory PlayerStatistics.empty(String userId) {
    return PlayerStatistics(
      id: '',
      userId: userId,
      matchesPlayed: 0,
      matchesWon: 0,
      matchesLost: 0,
      winRate: 0,
      kills: 0,
      deaths: 0,
      kdRatio: 0,
      assists: 0,
      mvpCount: 0,
      tournamentsPlayed: 0,
      tournamentsWon: 0,
      prizeMoneyEarned: 0,
      walletEarnings: 0,
      rankingScore: 0,
    );
  }

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    return PlayerStatistics(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      matchesPlayed: json['matches_played'] as int? ?? 0,
      matchesWon: json['matches_won'] as int? ?? 0,
      matchesLost: json['matches_lost'] as int? ?? 0,
      winRate: double.tryParse(json['win_rate'].toString()) ?? 0,
      kills: json['kills'] as int? ?? 0,
      deaths: json['deaths'] as int? ?? 0,
      kdRatio: double.tryParse(json['kd_ratio'].toString()) ?? 0,
      assists: json['assists'] as int? ?? 0,
      mvpCount: json['mvp_count'] as int? ?? 0,
      tournamentsPlayed: json['tournaments_played'] as int? ?? 0,
      tournamentsWon: json['tournaments_won'] as int? ?? 0,
      prizeMoneyEarned: double.tryParse(json['prize_money_earned'].toString()) ?? 0,
      walletEarnings: double.tryParse(json['wallet_earnings'].toString()) ?? 0,
      rankingScore: double.tryParse(json['ranking_score'].toString()) ?? 0,
      currentRank: json['current_rank'] as int?,
      previousRank: json['previous_rank'] as int?,
    );
  }
}
