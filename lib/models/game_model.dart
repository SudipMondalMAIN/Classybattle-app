/// Mirrors app/schemas/game.py -> ProfileFieldSchema on the backend.
/// Describes one field the user must fill in for a game's in-game
/// profile (e.g. IGN, UID).
class ProfileFieldModel {
  final String key;
  final String label;
  final String type;
  final bool required;

  ProfileFieldModel({
    required this.key,
    required this.label,
    this.type = 'string',
    this.required = true,
  });

  factory ProfileFieldModel.fromJson(Map<String, dynamic> json) {
    return ProfileFieldModel(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? true,
    );
  }
}

/// Mirrors app/schemas/game.py -> GameRead on the backend.
class GameModel {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final bool isActive;
  final List<ProfileFieldModel> profileSchema;

  GameModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.isActive,
    this.profileSchema = const [],
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      profileSchema: (json['profile_schema'] as List?)
              ?.map((e) => ProfileFieldModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}