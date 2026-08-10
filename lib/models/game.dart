/// Mirrors app/schemas/game.py -> ProfileFieldSchema.
/// Describes one input field a game's profile form needs
/// (e.g. Free Fire: {key: "nickname", label: "In-game Name"}).
class ProfileFieldSchema {
  final String key;
  final String label;
  final String type; // "string" | "number" (backend default: string)
  final bool required;

  ProfileFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
  });

  factory ProfileFieldSchema.fromJson(Map<String, dynamic> json) {
    return ProfileFieldSchema(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? true,
    );
  }
}

/// Mirrors app/schemas/game.py -> GameRead.
class Game {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final bool isActive;
  final List<ProfileFieldSchema> profileSchema;

  Game({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.isActive,
    required this.profileSchema,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      profileSchema: ((json['profile_schema'] as List?) ?? [])
          .map((e) => ProfileFieldSchema.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Mirrors app/schemas/game.py -> UserGameProfileRead.
/// One per (user, game) — backend enforces this with a unique constraint,
/// so once saved it's reused automatically for every tournament of that game.
class UserGameProfile {
  final String id;
  final String gameId;
  final Map<String, dynamic> data;

  UserGameProfile({required this.id, required this.gameId, required this.data});

  factory UserGameProfile.fromJson(Map<String, dynamic> json) {
    return UserGameProfile(
      id: json['id'] as String,
      gameId: json['game_id'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}
