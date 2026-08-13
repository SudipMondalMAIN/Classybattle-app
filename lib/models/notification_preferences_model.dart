/// Mirrors app/schemas/notification.py -> NotificationPreferenceRead on
/// the backend. Real, persisted per-user toggles -- not local-only state.
class NotificationPreferencesModel {
  final bool inAppEnabled;
  final bool pushEnabled;
  final bool emailEnabled;

  const NotificationPreferencesModel({
    required this.inAppEnabled,
    required this.pushEnabled,
    required this.emailEnabled,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
    );
  }

  NotificationPreferencesModel copyWith({
    bool? inAppEnabled,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return NotificationPreferencesModel(
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}
