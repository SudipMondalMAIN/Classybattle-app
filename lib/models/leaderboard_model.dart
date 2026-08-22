/// Mirrors app/schemas/leaderboard.py -> LeaderboardUserBrief. Lightweight
/// name/avatar info the leaderboard endpoint joins in per-row so the app
/// doesn't need one profile request per player.
///
/// avatar_id is one of the 6 avatars bundled inside the app
/// (assets/avatars/avatar_1.png ... avatar_6.png) -- same as everywhere
/// else in the app (header, profile card, participants list). The
/// backend never returns a network avatar image URL.
class LeaderboardUserBrief {
  final String id;
  final String fullName;
  final String playerUid;
  final String? avatarId;

  LeaderboardUserBrief({
    required this.id,
    required this.fullName,
    required this.playerUid,
    this.avatarId,
  });

  factory LeaderboardUserBrief.fromJson(Map<String, dynamic> json) {
    return LeaderboardUserBrief(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      playerUid: json['player_uid'] as String? ?? '',
      avatarId: json['avatar_id'] as String?,
    );
  }
}

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
  final LeaderboardUserBrief? user;

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
    this.user,
  });

  /// Best-effort display name -- falls back to a short player id when
  /// the joined user brief is missing (e.g. deleted account).
  String get displayName =>
      (user != null && user!.fullName.isNotEmpty)
          ? user!.fullName
          : 'Player ${userId.substring(0, 8)}';

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
      user: json['user'] == null
          ? null
          : LeaderboardUserBrief.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}