/// Mirrors app/schemas/tournament.py -> TournamentListItem on the backend.
///
/// `startsAt` is the slot's absolute scheduled kickoff (null for one-off
/// custom tournaments created before this field existed, or -- in
/// practice never for new ones, since the backend now stamps
/// created_at into it). Always display via formatIstDateTime /
/// formatIstTime so it reads as 12-hour IST regardless of device
/// timezone -- never toLocal() or a bare DateFormat.
class TournamentModel {
  final String id;
  final String tournamentUid;
  final String title;
  final String slug;
  final String gameId;
  final String? bannerUrl;
  final double entryFee;
  final double prizePool;
  final String prizeType; // rank | per_kill | win
  final double? perKillAmount;
  final double? winAmount;
  final int maxPlayers;
  final int currentPlayers;
  final String status; // scheduled | live | completed | cancelled
  final String visibility;
  final bool isFeatured;
  final String registrationMode;
  final int teamSize;
  final DateTime? startsAt;

  TournamentModel({
    required this.id,
    required this.tournamentUid,
    required this.title,
    required this.slug,
    required this.gameId,
    this.bannerUrl,
    required this.entryFee,
    required this.prizePool,
    required this.prizeType,
    this.perKillAmount,
    this.winAmount,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.status,
    required this.visibility,
    required this.isFeatured,
    required this.registrationMode,
    required this.teamSize,
    this.startsAt,
  });

  bool get isLive => status == 'live';

  int get slotsLeft => (maxPlayers - currentPlayers).clamp(0, maxPlayers);

  /// Best label + value for the reward badge shown on tournament
  /// cards -- mirrors PrizePoolSection's per-type logic so listings
  /// stay consistent with the tournament details screen.
  String get prizeBadgeLabel => switch (prizeType) {
    'per_kill' => 'Per Kill',
    'win' => 'Win Bonus',
    _ => 'Prize Pool',
  };

  double get prizeBadgeAmount => switch (prizeType) {
    'per_kill' => perKillAmount ?? 0,
    'win' => winAmount ?? 0,
    _ => prizePool,
  };

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'] as String,
      tournamentUid: json['tournament_uid'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      gameId: json['game_id'] as String,
      bannerUrl: json['banner_url'] as String?,
      entryFee: double.tryParse('${json['entry_fee']}') ?? 0,
      prizePool: double.tryParse('${json['prize_pool']}') ?? 0,
      prizeType: json['prize_type'] as String? ?? 'rank',
      perKillAmount: json['per_kill_amount'] != null
          ? double.tryParse('${json['per_kill_amount']}')
          : null,
      winAmount: json['win_amount'] != null
          ? double.tryParse('${json['win_amount']}')
          : null,
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 0,
      currentPlayers: (json['current_players'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      visibility: json['visibility'] as String,
      isFeatured: json['is_featured'] as bool? ?? false,
      registrationMode: json['registration_mode'] as String,
      teamSize: (json['team_size'] as num?)?.toInt() ?? 1,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
    );
  }
}
