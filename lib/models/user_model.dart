/// Mirrors app/schemas/user.py -> UserRead on the backend.
///
/// avatar_id is one of a fixed set of 6 avatars bundled inside the app
/// (assets/avatars/avatar_1.png ... avatar_6.png) -- the backend never
/// returns an avatar image URL, so the UI must map avatar_id to a
/// bundled asset rather than trying to load it from the network.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String playerUid;
  final String? avatarId;
  final bool isEmailVerified;
  final String? bio;
  final String? country;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.playerUid,
    this.avatarId,
    this.isEmailVerified = false,
    this.bio,
    this.country,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      playerUid: json['player_uid'] as String,
      avatarId: json['avatar_id'] as String?,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      bio: json['bio'] as String?,
      country: json['country'] as String?,
    );
  }
}
