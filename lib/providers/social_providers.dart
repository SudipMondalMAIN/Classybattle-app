import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/social_model.dart';
import '../services/social_service.dart';

/// A public player profile, keyed by user id -- used by the public
/// profile screen reached from the leaderboard.
final publicProfileProvider =
    FutureProvider.family<PublicProfileModel, String>((ref, userId) {
  return socialService.fetchProfile(userId);
});
