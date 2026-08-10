/// Mirrors app/schemas/tournament.py -> TournamentListItem (list) and
/// TournamentRead (detail) in the FastAPI backend. Kept as one class with
/// nullable detail-only fields to avoid duplicating parsing logic.
class Tournament {
  final String id;
  final String tournamentUid;
  final String title;
  final String slug;
  final String? description;
  final String? rules;
  final String gameId;
  final String? bannerUrl;
  final String? coverUrl;
  final String? organizer;
  final double entryFee;
  final double prizePool;
  final int maxPlayers;
  final int currentPlayers;
  final String status; // scheduled | live | completed | cancelled
  final String visibility;
  final bool isFeatured;
  final String registrationMode; // solo | team_invite | auto_random
  final int teamSize;
  final String? roomId;
  final String? roomPassword;
  final DateTime? publishedAt;

  Tournament({
    required this.id,
    required this.tournamentUid,
    required this.title,
    required this.slug,
    this.description,
    this.rules,
    required this.gameId,
    this.bannerUrl,
    this.coverUrl,
    this.organizer,
    required this.entryFee,
    required this.prizePool,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.status,
    required this.visibility,
    required this.isFeatured,
    required this.registrationMode,
    required this.teamSize,
    this.roomId,
    this.roomPassword,
    this.publishedAt,
  });

  int get slotsLeft => (maxPlayers - currentPlayers).clamp(0, maxPlayers);
  bool get isFull => currentPlayers >= maxPlayers;

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      tournamentUid: json['tournament_uid'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      rules: json['rules'] as String?,
      gameId: json['game_id'] as String,
      bannerUrl: json['banner_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      organizer: json['organizer'] as String?,
      entryFee: double.tryParse(json['entry_fee'].toString()) ?? 0,
      prizePool: double.tryParse(json['prize_pool'].toString()) ?? 0,
      maxPlayers: json['max_players'] as int,
      currentPlayers: json['current_players'] as int,
      status: json['status'] as String,
      visibility: json['visibility'] as String,
      isFeatured: json['is_featured'] as bool? ?? false,
      registrationMode: json['registration_mode'] as String,
      teamSize: json['team_size'] as int? ?? 1,
      roomId: json['room_id'] as String?,
      roomPassword: json['room_password'] as String?,
      publishedAt:
          json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
    );
  }
}
