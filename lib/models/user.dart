/// Mirrors app/schemas/user.py -> UserRead in the FastAPI backend.
class AppUser {
  final String id;
  final int shortId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String playerUid;
  final String role;
  final String status;
  final bool isEmailVerified;
  final bool isActive;
  final String? country;
  final String? avatarId;
  final String? bio;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.shortId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.playerUid,
    required this.role,
    required this.status,
    required this.isEmailVerified,
    required this.isActive,
    this.country,
    this.avatarId,
    this.bio,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      shortId: json['short_id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      playerUid: json['player_uid'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      isEmailVerified: json['is_email_verified'] as bool,
      isActive: json['is_active'] as bool,
      country: json['country'] as String?,
      avatarId: json['avatar_id'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
