/// Mirrors app/schemas/game.py -> GameRead on the backend.
class GameModel {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final bool isActive;

  GameModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.isActive,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
