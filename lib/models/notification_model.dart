/// Mirrors the backend's `NotificationEventType` enum
/// (app/models/notification.py). Kept as a plain string-backed enum so an
/// event type the app doesn't yet recognise degrades to `general` instead
/// of crashing.
enum NotificationEventType {
  general,
  userRegistration,
  tournamentCreated,
  tournamentUpdated,
  tournamentCancelled,
  registrationSuccessful,
  registrationCancelled,
  matchCreated,
  matchStarted,
  matchCompleted,
  roomDetailsPublished,
  liveMatchStarted,
  matchResultApproved,
  winnerDeclared,
  prizeDistributed,
  walletCredited,
  walletDebited,
  refundCompleted,
  adminBroadcast,
  systemAnnouncement;

  static NotificationEventType fromRaw(String? raw) {
    switch (raw) {
      case 'user_registration':
        return NotificationEventType.userRegistration;
      case 'tournament_created':
        return NotificationEventType.tournamentCreated;
      case 'tournament_updated':
        return NotificationEventType.tournamentUpdated;
      case 'tournament_cancelled':
        return NotificationEventType.tournamentCancelled;
      case 'registration_successful':
        return NotificationEventType.registrationSuccessful;
      case 'registration_cancelled':
        return NotificationEventType.registrationCancelled;
      case 'match_created':
        return NotificationEventType.matchCreated;
      case 'match_started':
        return NotificationEventType.matchStarted;
      case 'match_completed':
        return NotificationEventType.matchCompleted;
      case 'room_details_published':
        return NotificationEventType.roomDetailsPublished;
      case 'live_match_started':
        return NotificationEventType.liveMatchStarted;
      case 'match_result_approved':
        return NotificationEventType.matchResultApproved;
      case 'winner_declared':
        return NotificationEventType.winnerDeclared;
      case 'prize_distributed':
        return NotificationEventType.prizeDistributed;
      case 'wallet_credited':
        return NotificationEventType.walletCredited;
      case 'wallet_debited':
        return NotificationEventType.walletDebited;
      case 'refund_completed':
        return NotificationEventType.refundCompleted;
      case 'admin_broadcast':
        return NotificationEventType.adminBroadcast;
      case 'system_announcement':
        return NotificationEventType.systemAnnouncement;
      default:
        return NotificationEventType.general;
    }
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.eventType,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.metaData,
  });

  final String id;
  final String title;
  final String body;
  final NotificationEventType eventType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metaData;

  /// Tournament id this notification refers to, when present — read from
  /// real backend `meta_data`, never guessed from the message text.
  String? get tournamentId {
    final v = metaData?['tournament_id'];
    return v == null ? null : v.toString();
  }

  String? get transactionId {
    final v = metaData?['transaction_id'];
    return v == null ? null : v.toString();
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      eventType: NotificationEventType.fromRaw(json['event_type'] as String?),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String).toLocal(),
      metaData: (json['meta_data'] as Map?)?.cast<String, dynamic>(),
    );
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      eventType: eventType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      metaData: metaData,
    );
  }
}
