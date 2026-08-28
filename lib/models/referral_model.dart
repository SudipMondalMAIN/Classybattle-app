/// Mirrors app/schemas/referral.py -> MyReferralCodeResponse on the backend.
class MyReferralCodeModel {
  final String referralCode;
  final int totalReferred;
  final int completedReferrals;
  final int pendingReferrals;
  final int onHoldReferrals;
  final double totalEarned;
  final int? nextMilestoneAt;
  final double? nextMilestoneBonus;

  MyReferralCodeModel({
    required this.referralCode,
    required this.totalReferred,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.onHoldReferrals,
    required this.totalEarned,
    this.nextMilestoneAt,
    this.nextMilestoneBonus,
  });

  factory MyReferralCodeModel.fromJson(Map<String, dynamic> json) {
    return MyReferralCodeModel(
      referralCode: json['referral_code'] as String? ?? '',
      totalReferred: json['total_referred'] as int? ?? 0,
      completedReferrals: json['completed_referrals'] as int? ?? 0,
      pendingReferrals: json['pending_referrals'] as int? ?? 0,
      onHoldReferrals: json['on_hold_referrals'] as int? ?? 0,
      totalEarned: double.tryParse('${json['total_earned']}') ?? 0,
      nextMilestoneAt: json['next_milestone_at'] as int?,
      nextMilestoneBonus: json['next_milestone_bonus'] == null
          ? null
          : double.tryParse('${json['next_milestone_bonus']}'),
    );
  }
}

/// Mirrors app/schemas/referral.py -> ReferralStatusItem on the backend.
/// Used both for a single "apply code" result and for the referral
/// history list.
class ReferralStatusItemModel {
  final String id;
  final String refereeName;
  final String status;
  final bool depositMet;
  final bool tournamentMet;
  final double? rewardAmount;
  final bool rewardCredited;
  final DateTime createdAt;

  ReferralStatusItemModel({
    required this.id,
    required this.refereeName,
    required this.status,
    required this.depositMet,
    required this.tournamentMet,
    this.rewardAmount,
    required this.rewardCredited,
    required this.createdAt,
  });

  factory ReferralStatusItemModel.fromJson(Map<String, dynamic> json) {
    return ReferralStatusItemModel(
      id: json['id'] as String? ?? '',
      refereeName: json['referee_name'] as String? ?? '—',
      status: json['status'] as String? ?? 'pending',
      depositMet: json['deposit_met'] as bool? ?? false,
      tournamentMet: json['tournament_met'] as bool? ?? false,
      rewardAmount: json['reward_amount'] == null
          ? null
          : double.tryParse('${json['reward_amount']}'),
      rewardCredited: json['reward_credited'] as bool? ?? false,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }
}
