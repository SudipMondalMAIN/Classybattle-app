import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_model.dart';
import '../services/referral_service.dart';

/// Public "how it works" / "how much you earn" rules -- admin-configured,
/// never hardcoded in the app.
final referralRulesProvider = FutureProvider.autoDispose<ReferralRulesModel>(
  (ref) {
    return referralService.fetchRules();
  },
);

/// The current user's referral code + running stats for the
/// "Refer & Earn" screen.
final myReferralCodeProvider = FutureProvider.autoDispose<MyReferralCodeModel>(
  (ref) {
    return referralService.fetchMyCode();
  },
);

/// Everyone the current user has referred, with each one's progress.
final referralHistoryProvider =
    FutureProvider.autoDispose<List<ReferralStatusItemModel>>((ref) {
  return referralService.fetchHistory();
});
