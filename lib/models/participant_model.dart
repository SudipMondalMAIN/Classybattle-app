/// Mirrors app/schemas/participant.py -> ParticipantRead /
/// ParticipantListItem on the backend. Used to know whether the
/// current user has already joined a tournament, and to power the
/// "My Tournaments" tab / stats row from real registration history.
class ParticipantModel {
  final String id;
  final String tournamentId;
  final String status; // registered | checked_in | ... | cancelled
  final double entryFeePaid;

  ParticipantModel({
    required this.id,
    required this.tournamentId,
    required this.status,
    required this.entryFeePaid,
  });

  bool get isActive => status != 'cancelled';

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      status: json['status'] as String? ?? 'registered',
      entryFeePaid: double.tryParse('${json['entry_fee_paid'] ?? 0}') ?? 0,
    );
  }
}

/// Mirrors app/schemas/prize.py -> PrizePayoutRead (only the fields
/// needed to total up real winnings for the "Your Tournaments" row).
class PrizePayoutModel {
  final String tournamentId;
  final double amount;
  final String status; // pending | processing | paid | failed | cancelled

  PrizePayoutModel({
    required this.tournamentId,
    required this.amount,
    required this.status,
  });

  factory PrizePayoutModel.fromJson(Map<String, dynamic> json) {
    return PrizePayoutModel(
      tournamentId: json['tournament_id'] as String,
      amount: double.tryParse('${json['amount']}') ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
