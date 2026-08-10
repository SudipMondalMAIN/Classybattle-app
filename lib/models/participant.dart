/// Mirrors app/schemas/participant.py -> ParticipantListItem / ParticipantRead.
class Participant {
  final String id;
  final String participantUid;
  final String tournamentId;
  final String status; // registered | checked_in | disqualified | cancelled ...
  final String paymentStatus;
  final DateTime joinedAt;

  Participant({
    required this.id,
    required this.participantUid,
    required this.tournamentId,
    required this.status,
    required this.paymentStatus,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      participantUid: json['participant_uid'] as String,
      tournamentId: json['tournament_id'] as String,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}
