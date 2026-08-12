/// Mirrors app/schemas/game.py -> UserGameProfileRead on the backend.
/// A user's saved in-game identity (nickname/UID etc.) for one game --
/// required before joining any tournament for that game
/// (see slot_routes._resolve_game_profile / GAME_PROFILE_REQUIRED).
class GameProfileModel {
  final String id;
  final String gameId;
  final Map<String, dynamic> data;

  GameProfileModel({
    required this.id,
    required this.gameId,
    required this.data,
  });

  factory GameProfileModel.fromJson(Map<String, dynamic> json) {
    return GameProfileModel(
      id: json['id'] as String,
      gameId: json['game_id'] as String,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
