/// Mirrors app/schemas/tournament.py -> TournamentListItem on the backend.
///
/// Note: the backend's match-refactored Tournament has no
/// registration/start/end window fields (see the schema file's
/// docstring) -- join is instant while status == scheduled. So there
/// is intentionally no `startsAt` / `timeLeft` field here; the UI
/// must not invent one.
class TournamentModel {
  final String id;
  final String tournamentUid;
  final String title;
  final String slug;
  final String gameId;
  final String? bannerUrl;
  final double entryFee;
  final double prizePool;
  final int maxPlayers;
  final int currentPlayers;
  final String status; // scheduled | live | completed | cancelled
  final String visibility;
  final bool isFeatured;
  final String registrationMode;
  final int teamSize;

  TournamentModel({
    required this.id,
    required this.tournamentUid,
    required this.title,
    required this.slug,
    required this.gameId,
    this.bannerUrl,
    required this.entryFee,
    required this.prizePool,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.status,
    required this.visibility,
    required this.isFeatured,
    required this.registrationMode,
    required this.teamSize,
  });

  bool get isLive => status == 'live';

  int get slotsLeft => (maxPlayers - currentPlayers).clamp(0, maxPlayers);

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
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 0,
      currentPlayers: (json['current_players'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      visibility: json['visibility'] as String,
      isFeatured: json['is_featured'] as bool? ?? false,
      registrationMode: json['registration_mode'] as String,
      teamSize: (json['team_size'] as num?)?.toInt() ?? 1,
    );
  }
}
