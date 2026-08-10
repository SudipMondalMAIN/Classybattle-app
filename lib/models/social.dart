/// Mirrors app/schemas/social.py -> PublicUserSummary.
class PublicUserSummary {
  final String id;
  final String fullName;
  final String playerUid;
  final String? country;

  PublicUserSummary({
    required this.id,
    required this.fullName,
    required this.playerUid,
    this.country,
  });

  factory PublicUserSummary.fromJson(Map<String, dynamic> json) {
    return PublicUserSummary(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      playerUid: json['player_uid'] as String,
      country: json['country'] as String?,
    );
  }
}

/// Mirrors app/schemas/social.py -> PlayerStatsSummary.
class PlayerStatsSummary {
  final int matchesPlayed;
  final int matchesWon;
  final double winRate;
  final double kdRatio;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final int? currentRank;

  PlayerStatsSummary({
    required this.matchesPlayed,
    required this.matchesWon,
    required this.winRate,
    required this.kdRatio,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
    this.currentRank,
  });

  factory PlayerStatsSummary.fromJson(Map<String, dynamic> json) {
    return PlayerStatsSummary(
      matchesPlayed: json['matches_played'] as int? ?? 0,
      matchesWon: json['matches_won'] as int? ?? 0,
      winRate: double.tryParse(json['win_rate'].toString()) ?? 0,
      kdRatio: double.tryParse(json['kd_ratio'].toString()) ?? 0,
      tournamentsPlayed: json['tournaments_played'] as int? ?? 0,
      tournamentsWon: json['tournaments_won'] as int? ?? 0,
      currentRank: json['current_rank'] as int?,
    );
  }
}

/// Mirrors app/schemas/social.py -> ProfileRead. Used for GET /social/profiles/{user_id}.
class PlayerProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String visibility;
  final bool isOnline;
  final int friendsCount;
  final int followersCount;
  final int followingCount;
  final PublicUserSummary? user;
  final PlayerStatsSummary? stats;
  final String? relationshipStatus; // self | friend | pending | blocked | none
  final bool? isFollowing;

  PlayerProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.visibility,
    required this.isOnline,
    required this.friendsCount,
    required this.followersCount,
    required this.followingCount,
    this.user,
    this.stats,
    this.relationshipStatus,
    this.isFollowing,
  });

  String get displayLabel => displayName ?? user?.fullName ?? 'Player';

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      isOnline: json['is_online'] as bool? ?? false,
      friendsCount: json['friends_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      user: json['user'] != null ? PublicUserSummary.fromJson(json['user']) : null,
      stats: json['stats'] != null ? PlayerStatsSummary.fromJson(json['stats']) : null,
      relationshipStatus: json['relationship_status'] as String?,
      isFollowing: json['is_following'] as bool?,
    );
  }
}

/// Mirrors app/models/moderation.py -> ReportReason.
enum ReportReason {
  cheating('cheating', 'Cheating'),
  harassment('harassment', 'Harassment'),
  abusiveLanguage('abusive_language', 'Abusive language'),
  noShow('no_show', 'No-show'),
  matchFixing('match_fixing', 'Match fixing'),
  impersonation('impersonation', 'Impersonation'),
  spam('spam', 'Spam'),
  other('other', 'Other');

  final String value;
  final String label;
  const ReportReason(this.value, this.label);
}
