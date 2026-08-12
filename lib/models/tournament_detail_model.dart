/// Mirrors app/schemas/tournament.py -> TournamentRead on the backend.
/// Used for the Tournament Details screen, which needs fields (rules,
/// room_id/room_password, mode_id/map_id, description, category...)
/// that the lighter TournamentListItem/TournamentModel doesn't carry.
class TournamentDetailModel {
  final String id;
  final String tournamentUid;
  final String title;
  final String slug;
  final String? description;
  final String? rules;
  final String gameId;
  final String? modeId;
  final String? mapId;
  final String? bannerUrl;
  final String? coverUrl;
  final String organizer;
  final double entryFee;
  final double prizePool;
  final int maxPlayers;
  final int currentPlayers;
  final String status; // scheduled | live | completed | cancelled
  final String visibility;
  final bool isFeatured;
  final String? roomId;
  final String? roomPassword;
  final DateTime? publishedAt;
  final DateTime? autoCompleteAt;
  final String registrationMode; // solo | team_invite | auto_random
  final int teamSize;
  final String? category; // solo | squad

  TournamentDetailModel({
    required this.id,
    required this.tournamentUid,
    required this.title,
    required this.slug,
    this.description,
    this.rules,
    required this.gameId,
    this.modeId,
    this.mapId,
    this.bannerUrl,
    this.coverUrl,
    required this.organizer,
    required this.entryFee,
    required this.prizePool,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.status,
    required this.visibility,
    required this.isFeatured,
    this.roomId,
    this.roomPassword,
    this.publishedAt,
    this.autoCompleteAt,
    required this.registrationMode,
    required this.teamSize,
    this.category,
  });

  bool get isLive => status == 'live';
  int get slotsLeft => (maxPlayers - currentPlayers).clamp(0, maxPlayers);
  bool get isFree => entryFee <= 0;
  bool get hasRoomDetails =>
      (roomId != null && roomId!.isNotEmpty) &&
      (roomPassword != null && roomPassword!.isNotEmpty);

  /// Time remaining until auto_complete_at (only meaningful once LIVE
  /// and the room has been published). Null when there's nothing to
  /// count down to, rather than a fabricated countdown.
  Duration? get timeLeft {
    if (autoCompleteAt == null) return null;
    final diff = autoCompleteAt!.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory TournamentDetailModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String);
    return TournamentDetailModel(
      id: json['id'] as String,
      tournamentUid: json['tournament_uid'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      rules: json['rules'] as String?,
      gameId: json['game_id'] as String,
      modeId: json['mode_id'] as String?,
      mapId: json['map_id'] as String?,
      bannerUrl: json['banner_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      organizer: json['organizer'] as String? ?? '',
      entryFee: double.tryParse('${json['entry_fee']}') ?? 0,
      prizePool: double.tryParse('${json['prize_pool']}') ?? 0,
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 0,
      currentPlayers: (json['current_players'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      visibility: json['visibility'] as String,
      isFeatured: json['is_featured'] as bool? ?? false,
      roomId: json['room_id'] as String?,
      roomPassword: json['room_password'] as String?,
      publishedAt: parseDate(json['published_at']),
      autoCompleteAt: parseDate(json['auto_complete_at']),
      registrationMode: json['registration_mode'] as String? ?? 'solo',
      teamSize: (json['team_size'] as num?)?.toInt() ?? 1,
      category: json['category'] as String?,
    );
  }
}
