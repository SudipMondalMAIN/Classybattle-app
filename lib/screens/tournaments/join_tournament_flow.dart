import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/game.dart';
import '../../models/participant.dart';
import '../../services/game_service.dart';
import '../../services/tournament_service.dart';
import '../../core/api_exception.dart';
import '../auth/auth_widgets.dart';
import 'game_profile_dialog.dart';

/// Full join flow for a tournament:
///  1. Loads the tournament's game (for its profile_schema) and the
///     user's saved profiles.
///  2. If a profile for that game already exists -> joins immediately,
///     no popup (this is the "don't ask again per game" behaviour).
///  3. If not -> shows [GameProfileDialog] once, saves it, then joins.
///
/// Returns the created [Participant] on success, or null if the user
/// cancelled or an error was already shown via snackbar.
Future<Participant?> runJoinTournamentFlow(
  BuildContext context, {
  required String tournamentId,
  required String gameId,
}) async {
  final gameService = GameService();
  final tournamentService = TournamentService();

  Game game;
  List<UserGameProfile> myProfiles;
  try {
    final games = await gameService.listGames();
    game = games.firstWhere((g) => g.id == gameId, orElse: () => games.first);
    myProfiles = await gameService.myGameProfiles();
  } on ApiException catch (e) {
    if (context.mounted) showAuthSnack(context, e.message);
    return null;
  }

  UserGameProfile? profile;
  final existing = myProfiles.where((p) => p.gameId == gameId);
  if (existing.isNotEmpty) {
    profile = existing.first;
  } else {
    if (!context.mounted) return null;
    profile = await showGameProfileDialog(context, game: game);
    if (profile == null) return null; // user cancelled
  }

  if (!context.mounted) return null;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
  );

  try {
    final participant = await tournamentService.register(
      tournamentId: tournamentId,
      gameProfileId: profile.id,
    );
    if (context.mounted) Navigator.of(context).pop(); // close loading
    if (context.mounted) {
      showAuthSnack(context, 'Tournament e join hoye gecho!', isError: false);
    }
    return participant;
  } on ApiException catch (e) {
    if (context.mounted) Navigator.of(context).pop(); // close loading
    if (context.mounted) showAuthSnack(context, e.message);
    return null;
  }
}
