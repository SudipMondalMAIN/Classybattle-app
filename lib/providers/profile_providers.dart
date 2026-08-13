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

/// Real win rate derived from the user's actual joined/won counts.
/// Null when there's no stats yet (logged out, or zero tournaments
/// joined -- a rate isn't meaningful with a zero denominator).
final winRateProvider = FutureProvider<double?>((ref) async {
  final stats = await ref.watch(myTournamentStatsProvider.future);
  if (stats == null || stats.joined == 0) return null;
  return (stats.won / stats.joined) * 100;
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
final myTournamentEntriesProvider = FutureProvider<List<MyTournamentEntry>>((ref) async {
  try {
    final regs = await tournamentService.fetchMyRegistrations(pageSize: 100);
    if (regs.items.isEmpty) return [];
    final all = await tournamentService.fetchTournaments(pageSize: 200);
    final byId = {for (final t in all.items) t.id: t};
    final entries = <MyTournamentEntry>[];
    for (final r in regs.items) {
      final t = byId[r.tournamentId];
      if (t == null) continue;
      entries.add(MyTournamentEntry(tournament: t, participantStatus: r.status));
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
