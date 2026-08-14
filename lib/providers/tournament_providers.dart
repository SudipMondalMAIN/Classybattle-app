import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_mode_model.dart';
import '../models/map_model.dart';
import '../models/participant_model.dart';
import '../models/participant_public_model.dart';
import '../models/prize_pool_model.dart';
import '../models/tournament_detail_model.dart';
import '../models/tournament_model.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/tournament_service.dart';

/// Which tab is selected on the Tournaments screen. Mirrors the
/// backend's real status aliases (see tournament_routes._STATUS_ALIASES)
/// plus a client-only "mine" tab backed by /users/me/registrations.
enum TournamentTab { all, live, upcoming, completed, mine }

extension TournamentTabX on TournamentTab {
  String get label => switch (this) {
    TournamentTab.all => 'All',
    TournamentTab.live => 'Live',
    TournamentTab.upcoming => 'Upcoming',
    TournamentTab.completed => 'Completed',
    TournamentTab.mine => 'My Tournaments',
  };

  String? get statusAlias => switch (this) {
    TournamentTab.all => null,
    TournamentTab.live => 'ongoing',
    TournamentTab.upcoming => 'upcoming',
    TournamentTab.completed => 'past',
    TournamentTab.mine => null,
  };
}

final selectedTournamentTabProvider = StateProvider<TournamentTab>(
  (ref) => TournamentTab.all,
);

final tournamentSearchQueryProvider = StateProvider<String>((ref) => '');

final tournamentGameFilterProvider = StateProvider<String?>((ref) => null);

/// Category filter (solo|squad|custom) — driven by tapping a home-screen
/// category box; null means no category filter applied.
final tournamentCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Full "All" list -- used to derive the Live/Upcoming sections at the
/// top of the Tournaments screen (matches the reference layout).
final allTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final search = ref.watch(tournamentSearchQueryProvider);
  final gameId = ref.watch(tournamentGameFilterProvider);
  final category = ref.watch(tournamentCategoryFilterProvider);
  final result = await tournamentService.fetchTournaments(
    search: search,
    gameId: gameId,
    category: category,
    pageSize: 100,
  );
  return result.items;
});

/// Live tournament count for the "Live" tab badge -- real count, not
/// hardcoded.
final liveTournamentsCountProvider = FutureProvider<int>((ref) async {
  final result = await tournamentService.fetchTournaments(
    status: 'ongoing',
    pageSize: 1,
  );
  return result.total;
});

/// Tournaments for whichever tab is currently selected (status-driven
/// tabs go straight to the backend filter; "My Tournaments" resolves
/// via the user's real registration history).
final tournamentsForSelectedTabProvider = FutureProvider<List<TournamentModel>>(
  (ref) async {
    final tab = ref.watch(selectedTournamentTabProvider);
    final search = ref.watch(tournamentSearchQueryProvider);
    final gameId = ref.watch(tournamentGameFilterProvider);
    final category = ref.watch(tournamentCategoryFilterProvider);

    if (tab == TournamentTab.all) {
      return ref.watch(allTournamentsProvider.future);
    }

    if (tab == TournamentTab.mine) {
      try {
        final regs = await tournamentService.fetchMyRegistrations();
        final ids = regs.items
            .where((r) => r.isActive)
            .map((r) => r.tournamentId)
            .toSet();
        if (ids.isEmpty) return [];
        final all = await tournamentService.fetchTournaments(pageSize: 100);
        var mine = all.items.where((t) => ids.contains(t.id)).toList();
        if (gameId != null)
          mine = mine.where((t) => t.gameId == gameId).toList();
        if (search.trim().isNotEmpty) {
          final q = search.trim().toLowerCase();
          mine = mine.where((t) => t.title.toLowerCase().contains(q)).toList();
        }
        return mine;
      } on UnauthenticatedException {
        return [];
      }
    }

    final result = await tournamentService.fetchTournaments(
      status: tab.statusAlias,
      search: search,
      gameId: gameId,
      category: category,
      pageSize: 100,
    );
    return result.items;
  },
);

/// Real "Your Tournaments" stats: joined / won / total winnings, all
/// derived from the user's actual registration + payout history.
class MyTournamentStats {
  const MyTournamentStats({
    required this.joined,
    required this.won,
    required this.totalWinnings,
  });
  final int joined;
  final int won;
  final double totalWinnings;
}

final myTournamentStatsProvider = FutureProvider<MyTournamentStats?>((
  ref,
) async {
  try {
    final regs = await tournamentService.fetchMyRegistrations(pageSize: 1);
    final payouts = await tournamentService.fetchMyPrizePayouts();
    final paid = payouts.where((p) => p.status == 'paid');
    final wonTournaments = paid.map((p) => p.tournamentId).toSet();
    final totalWinnings = paid.fold<double>(0, (sum, p) => sum + p.amount);
    return MyTournamentStats(
      joined: regs.total,
      won: wonTournaments.length,
      totalWinnings: totalWinnings,
    );
  } on UnauthenticatedException {
    return null;
  }
});

/// ---- Tournament Details screen ----

final tournamentDetailProvider =
    FutureProvider.family<TournamentDetailModel, String>((ref, id) {
      return tournamentService.fetchTournamentDetail(id);
    });

final tournamentGameModeProvider =
    FutureProvider.family<GameModeModel?, String?>((ref, modeId) {
      return tournamentService.fetchGameMode(modeId);
    });

final tournamentMapProvider = FutureProvider.family<MapModel?, String?>((
  ref,
  mapId,
) {
  return tournamentService.fetchMap(mapId);
});

final tournamentPrizePoolProvider =
    FutureProvider.family<PrizePoolModel?, String>((ref, tournamentId) {
      return tournamentService.fetchPrizePool(tournamentId);
    });

final myRegistrationProvider = FutureProvider.family<ParticipantModel?, String>(
  (ref, tournamentId) {
    return tournamentService.fetchMyRegistration(tournamentId);
  },
);

/// Full public roster for a tournament's details screen — avatar/name/
/// in-game nickname+uid for every participant, plus rank/win/prize once
/// the tournament has results.
final tournamentParticipantsProvider =
    FutureProvider.family<List<ParticipantPublicModel>, String>((
      ref,
      tournamentId,
    ) async {
      final result = await tournamentService.fetchTournamentParticipants(
        tournamentId,
      );
      return result.items;
    });
