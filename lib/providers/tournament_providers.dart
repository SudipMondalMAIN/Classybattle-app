import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_match_claim_model.dart';
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

/// Format filter (solo|duo|squad|free|custom) — driven by tapping a
/// home-screen category box OR a filter chip on the Tournaments screen;
/// null means no filter applied. Sent straight through to the backend's
/// `format` query param (see tournament_routes.list_tournaments).
final tournamentCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Full "All" list -- used to derive the Live/Upcoming sections at the
/// top of the Tournaments screen (matches the reference layout).
final allTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final search = ref.watch(tournamentSearchQueryProvider);
  final gameId = ref.watch(tournamentGameFilterProvider);
  final format = ref.watch(tournamentCategoryFilterProvider);
  final result = await tournamentService.fetchTournaments(
    search: search,
    gameId: gameId,
    format: format,
    pageSize: 100,
  );
  return result.items;
});

/// User-hosted Custom Tournaments (is_custom=true) -- powers the
/// dedicated Custom Tournaments browse page, kept separate from the
/// main Tournaments screen and its tabs.
final customTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final result = await tournamentService.fetchTournaments(
    isCustom: true,
    pageSize: 100,
  );
  // Completed (and cancelled) custom tournaments have nothing left to
  // join/host -- keep the browse list to scheduled/live ones only.
  return result.items
      .where((t) => t.status != 'completed' && t.status != 'cancelled')
      .toList();
});

/// Tournaments for a single fixed `format` value (solo|duo|squad|free|
/// cs_1v1|cs_head|cs_4v4|lw_1v1|lw_head|br_survive) -- powers each
/// dedicated per-box-type browse page (mirrors [customTournamentsProvider]
/// but keyed by format instead of is_custom). Completed/cancelled ones
/// have nothing left to join, so they're filtered out same as Custom.
final formatTournamentsProvider =
    FutureProvider.family<List<TournamentModel>, String>((ref, format) async {
      final result = await tournamentService.fetchTournaments(
        format: format,
        status: 'active',
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
        final active = regs.items.where((r) => r.isActive).toList();
        if (active.isEmpty) return [];
        // Resolve each registered tournament directly by ID rather than
        // matching against the bulk `/tournaments` list -- that list
        // hides PRIVATE tournaments for non-admin callers, and Custom
        // Tournaments default to visibility=PRIVATE, so matching against
        // it silently dropped every custom tournament from this tab.
        final tournaments = await Future.wait(
          active.map(
            (r) => tournamentService.fetchTournamentById(r.tournamentId),
          ),
        );
        var mine = tournaments.whereType<TournamentModel>().toList();
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
      format: category,
      pageSize: 100,
    );
    return result.items;
  },
);

/// Tournaments the current user has actually joined -- powers the
/// dedicated My Tournaments screen (bottom nav). Resolves via the
/// user's real registration history, same approach as the "mine" tab
/// on the Tournaments screen: resolving each registered tournament
/// directly by ID (rather than matching against the bulk `/tournaments`
/// list) because that list hides PRIVATE tournaments for non-admin
/// callers, and Custom Tournaments default to visibility=PRIVATE.
final myJoinedTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  try {
    final regs = await tournamentService.fetchMyRegistrations();
    final active = regs.items.where((r) => r.isActive).toList();
    if (active.isEmpty) return [];
    final tournaments = await Future.wait(
      active.map((r) => tournamentService.fetchTournamentById(r.tournamentId)),
    );
    return tournaments.whereType<TournamentModel>().toList();
  } on UnauthenticatedException {
    return [];
  }
});

/// Real "Your Tournaments" stats: joined / won / total winnings / win
/// rate, sourced from GET /users/me/stats (backend PlayerStatistics),
/// which covers wins from both the admin-run and custom 1v1 payout
/// flows.
class MyTournamentStats {
  const MyTournamentStats({
    required this.joined,
    required this.won,
    required this.totalWinnings,
    required this.winRate,
  });
  final int joined;
  final int won;
  final double totalWinnings;
  final double? winRate;
}

final myTournamentStatsProvider = FutureProvider<MyTournamentStats?>((
  ref,
) async {
  try {
    final stats = await tournamentService.fetchMyStats();
    return MyTournamentStats(
      joined: stats.joined,
      won: stats.won,
      totalWinnings: stats.totalWinnings,
      winRate: stats.winRate,
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

/// Self-declared win/loss claim state for a 1v1 Custom Tournament (null
/// if this isn't an eligible custom 1v1 tournament, or the user isn't a
/// participant, or nothing's been submitted / room isn't live yet).
final customMatchClaimProvider =
    FutureProvider.family<CustomMatchClaimPairModel?, String>((
      ref,
      tournamentId,
    ) {
      return tournamentService.fetchCustomResult(tournamentId);
    });
