/// Self-declared win/loss claim for a 1v1 Custom Tournament.
///
/// status: pending_review | auto_resolved | admin_approved | rejected
/// outcome: win | loss
class CustomMatchClaimModel {
  const CustomMatchClaimModel({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.outcome,
    this.proofUrl,
    required this.status,
    required this.submittedAt,
    this.resolvedAt,
    this.rejectionReason,
  });

  final String id;
  final String tournamentId;
  final String userId;
  final String outcome;
  final String? proofUrl;
  final String status;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final String? rejectionReason;

  bool get isWin => outcome == 'win';
  bool get isPending => status == 'pending_review';
  bool get isResolved => status == 'auto_resolved' || status == 'admin_approved';
  bool get isRejected => status == 'rejected';

  factory CustomMatchClaimModel.fromJson(Map<String, dynamic> json) {
    return CustomMatchClaimModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      userId: json['user_id'] as String,
      outcome: json['outcome'] as String,
      proofUrl: json['proof_url'] as String?,
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

/// Both players' claim state for a tournament -- lets the UI show
/// "waiting for opponent" / "confirmed & paid" / etc without a 2nd call.
class CustomMatchClaimPairModel {
  const CustomMatchClaimPairModel({
    this.myClaim,
    this.opponentClaim,
    required this.resolved,
  });

  final CustomMatchClaimModel? myClaim;
  final CustomMatchClaimModel? opponentClaim;
  final bool resolved;

  factory CustomMatchClaimPairModel.fromJson(Map<String, dynamic> json) {
    return CustomMatchClaimPairModel(
      myClaim: json['my_claim'] != null
          ? CustomMatchClaimModel.fromJson(json['my_claim'] as Map<String, dynamic>)
          : null,
      opponentClaim: json['opponent_claim'] != null
          ? CustomMatchClaimModel.fromJson(json['opponent_claim'] as Map<String, dynamic>)
          : null,
      resolved: json['resolved'] as bool? ?? false,
    );
  }
}
