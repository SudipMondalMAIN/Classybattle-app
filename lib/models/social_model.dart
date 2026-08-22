/// Mirrors app/schemas/social.py -- Phase 15A Social System.

/// GET /social/profiles/{user_id} -> PublicUserSummary (nested under
/// ProfileRead.user).
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
      fullName: json['full_name'] as String? ?? '',
      playerUid: json['player_uid'] as String? ?? '',
      country: json['country'] as String?,
    );
  }
}

/// PlayerStatsSummary -- tournament/match stats only, never match/
/// tournament *history* (that's a separate, gated endpoint).
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
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
      kdRatio: (json['kd_ratio'] as num?)?.toDouble() ?? 0,
      tournamentsPlayed: json['tournaments_played'] as int? ?? 0,
      tournamentsWon: json['tournaments_won'] as int? ?? 0,
      currentRank: json['current_rank'] as int?,
    );
  }
}

/// Viewer's relationship to the profile being looked at.
enum ProfileRelationship { self_, friend, pending, incoming, blocked, none }

ProfileRelationship _relationshipFromString(String? value) {
  switch (value) {
    case 'self':
      return ProfileRelationship.self_;
    case 'friend':
      return ProfileRelationship.friend;
    case 'pending':
      return ProfileRelationship.pending;
    case 'incoming':
      return ProfileRelationship.incoming;
    case 'blocked':
      return ProfileRelationship.blocked;
    default:
      return ProfileRelationship.none;
  }
}

/// GET /social/profiles/{user_id} -> ProfileRead. Used for the public
/// profile screen reached by tapping a player on the leaderboard.
class PublicProfileModel {
  final String id;
  final String userId;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isOnline;
  final int friendsCount;
  final int followersCount;
  final PublicUserSummary? user;
  final PlayerStatsSummary? stats;
  final ProfileRelationship relationship;
  final String? friendshipId;

  PublicProfileModel({
    required this.id,
    required this.userId,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.isOnline,
    required this.friendsCount,
    required this.followersCount,
    this.user,
    this.stats,
    required this.relationship,
    this.friendshipId,
  });

  /// Best-effort display name -- profile display_name first, then the
  /// account's real full name, then the player uid.
  String get name {
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!;
    if (user != null && user!.fullName.isNotEmpty) return user!.fullName;
    return user?.playerUid ?? 'Player';
  }

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      friendsCount: json['friends_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      user: json['user'] == null
          ? null
          : PublicUserSummary.fromJson(json['user'] as Map<String, dynamic>),
      stats: json['stats'] == null
          ? null
          : PlayerStatsSummary.fromJson(json['stats'] as Map<String, dynamic>),
      relationship: _relationshipFromString(json['relationship_status'] as String?),
      // Not returned by ProfileRead directly -- filled in by the service
      // layer from the incoming/outgoing friend-request lists when needed.
      friendshipId: null,
    );
  }

  PublicProfileModel copyWith({
    ProfileRelationship? relationship,
    String? friendshipId,
  }) {
    return PublicProfileModel(
      id: id,
      userId: userId,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      isOnline: isOnline,
      friendsCount: friendsCount,
      followersCount: followersCount,
      user: user,
      stats: stats,
      relationship: relationship ?? this.relationship,
      friendshipId: friendshipId ?? this.friendshipId,
    );
  }
}

/// POST /social/friends/requests -> FriendshipRead.
class FriendshipModel {
  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;

  FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
