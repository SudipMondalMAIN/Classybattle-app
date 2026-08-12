import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../models/game_profile_model.dart';
import '../services/game_profile_service.dart';
import '../services/home_service.dart' show homeService, UnauthenticatedException;

/// All active games (used by the Game Profiles screen to list every
/// game the user might need to set a profile for).
final allGamesProvider = FutureProvider<List<GameModel>>((ref) {
  return homeService.fetchGames();
});

/// All saved game profiles for the current user. Empty list (not an
/// error) when the user isn't logged in, so the screen can still show
/// the "Not set up yet" state instead of an error card.
final myGameProfilesProvider = FutureProvider<List<GameProfileModel>>((
  ref,
) async {
  try {
    return await gameProfileService.fetchMyGameProfiles();
  } on UnauthenticatedException {
    return [];
  }
});

/// Whether the current user already has a saved profile for [gameId].
/// Derived from [myGameProfilesProvider] rather than a separate call.
final hasGameProfileProvider = FutureProvider.family<bool, String>((
  ref,
  gameId,
) async {
  final profiles = await ref.watch(myGameProfilesProvider.future);
  return profiles.any((p) => p.gameId == gameId);
});