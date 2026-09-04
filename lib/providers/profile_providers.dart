import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_preferences_model.dart';
import '../models/tournament_model.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/settings_service.dart';
import '../services/tournament_service.dart';
import 'tournament_providers.dart' show myTournamentStatsProvider;

/// Tabs on the Profile screen's "My Tournaments" section. Mirrors the
/// real states a joined tournament can be in, derived from the user's
/// actual registrations -- there is no separate "joined" backend
/// concept beyond "has an active registration".
enum ProfileTournamentTab { joined, upcoming, completed, cancelled }

extension ProfileTournamentTabX on ProfileTournamentTab {
  String get label => switch (this) {
        ProfileTournamentTab.joined => 'Joined',
        ProfileTournamentTab.upcoming => 'Upcoming',
        ProfileTournamentTab.completed => 'Completed',
        ProfileTournamentTab.cancelled => 'Cancelled',
      };
}

final profileTournamentTabProvider =
    StateProvider<ProfileTournamentTab>((ref) => ProfileTournamentTab.joined);

/// Real win rate, now sourced directly from the backend
/// (MyTournamentStats.winRate via GET /users/me/stats) instead of being
/// derived client-side from joined/won.
final winRateProvider = FutureProvider<double?>((ref) async {
  final stats = await ref.watch(myTournamentStatsProvider.future);
  return stats?.winRate;
});

/// One combined participant+tournament record, so tournament cards can
/// show both the tournament's own info and the user's real
/// registration status for it, without guessing.
class MyTournamentEntry {
  const MyTournamentEntry({required this.tournament, required this.participantStatus});
  final TournamentModel tournament;
  final String participantStatus;
}

/// All of the current user's real registrations, joined against the
/// matching tournaments. Empty (not error) when signed out.
///
/// Each registered tournament is resolved with a direct
/// GET /tournaments/{id} lookup rather than matched against the bulk
/// `/tournaments` list. The bulk list hides PRIVATE tournaments for
/// non-admin callers, and Custom Tournaments default to
/// visibility=PRIVATE -- matching against that list silently dropped
/// every custom tournament a user joined or hosted, leaving every tab
/// (Joined/Upcoming/Completed/Cancelled) empty for anyone whose
/// history is mostly custom tournaments.
final myTournamentEntriesProvider = FutureProvider<List<MyTournamentEntry>>((ref) async {
  try {
    final regs = await tournamentService.fetchMyRegistrations(pageSize: 100);
    if (regs.items.isEmpty) return [];
    final tournaments = await Future.wait(
      regs.items.map((r) => tournamentService.fetchTournamentById(r.tournamentId)),
    );
    final entries = <MyTournamentEntry>[];
    for (var i = 0; i < regs.items.length; i++) {
      final t = tournaments[i];
      if (t == null) continue; // tournament since deleted -- skip
      entries.add(MyTournamentEntry(tournament: t, participantStatus: regs.items[i].status));
    }
    return entries;
  } on UnauthenticatedException {
    return [];
  }
});

/// Entries for whichever Profile tournament tab is currently selected.
final myTournamentsForTabProvider = FutureProvider<List<MyTournamentEntry>>((ref) async {
  final tab = ref.watch(profileTournamentTabProvider);
  final entries = await ref.watch(myTournamentEntriesProvider.future);
  return entries.where((e) {
    final tStatus = e.tournament.status;
    switch (tab) {
      case ProfileTournamentTab.cancelled:
        return e.participantStatus == 'cancelled' || tStatus == 'cancelled';
      case ProfileTournamentTab.completed:
        return tStatus == 'completed' && e.participantStatus != 'cancelled';
      case ProfileTournamentTab.upcoming:
        return tStatus == 'scheduled' && e.participantStatus != 'cancelled';
      case ProfileTournamentTab.joined:
        return e.participantStatus != 'cancelled';
    }
  }).toList();
});

/// Real, persisted notification toggles for the Settings screen.
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferencesModel?>((ref) async {
  try {
    return await settingsService.fetchNotificationPreferences();
  } on UnauthenticatedException {
    return null;
  }
});
