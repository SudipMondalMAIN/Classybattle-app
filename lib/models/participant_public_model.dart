/// Mirrors app/schemas/participant.py -> ParticipantPublicView on the
/// backend. Powers the "Participants" section on the Tournament Details
/// screen: every participant's avatar/name/in-game nickname+uid, and —
/// once the tournament has results — their rank/win/prize too.
class ParticipantPublicModel {
  final String id;
  final String participantUid;
  final String tournamentId;
  final String registrationType; // solo | duo | squad | team
  final String? teamName;
  final String
  status; // pending | confirmed | cancelled | rejected | checked_in
  final DateTime joinedAt;

  final String userId;
  final String fullName;
  final String? avatarId;
  final String playerUid;

  final String? ingameNickname;
  final String? ingameUid;

  final int? kills;
  final bool isWinner;
  final int? rank;
  final double? winningAmount;

  ParticipantPublicModel({
    required this.id,
    required this.participantUid,
    required this.tournamentId,
    required this.registrationType,
    this.teamName,
    required this.status,
    required this.joinedAt,
    required this.userId,
    required this.fullName,
    this.avatarId,
    required this.playerUid,
    this.ingameNickname,
    this.ingameUid,
    this.kills,
    this.isWinner = false,
    this.rank,
    this.winningAmount,
  });

  /// Whether this participant has a declared result yet (tournament
  /// completed and an admin entered kills/rank/winner for them).
  bool get hasResult => rank != null || isWinner || kills != null;

  factory ParticipantPublicModel.fromJson(Map<String, dynamic> json) {
    return ParticipantPublicModel(
      id: json['id'] as String,
      participantUid: json['participant_uid'] as String? ?? '',
      tournamentId: json['tournament_id'] as String,
      registrationType: json['registration_type'] as String? ?? 'solo',
      teamName: json['team_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      joinedAt:
          DateTime.tryParse(json['joined_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarId: json['avatar_id'] as String?,
      playerUid: json['player_uid'] as String? ?? '',
      ingameNickname: json['ingame_nickname'] as String?,
      ingameUid: json['ingame_uid'] as String?,
      kills: (json['kills'] as num?)?.toInt(),
      isWinner: json['is_winner'] as bool? ?? false,
      rank: (json['rank'] as num?)?.toInt(),
      winningAmount: json['winning_amount'] == null
          ? null
          : double.tryParse('${json['winning_amount']}'),
    );
  }
}
