/// Mirrors app/schemas/game_mode.py -> GameModeRead on the backend
/// (only the fields the Tournament Details "Info" card needs).
class GameModeModel {
  final String id;
  final String name;
  final String? shortName;

  GameModeModel({required this.id, required this.name, this.shortName});

  factory GameModeModel.fromJson(Map<String, dynamic> json) {
    return GameModeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
    );
  }
}
