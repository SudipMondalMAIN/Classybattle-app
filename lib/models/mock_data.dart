import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TournamentStatus { upcoming, live, completed }

class Tournament {
  final String id;
  final String title;
  final String game; // FREE FIRE, BGMI, CODM, VALORANT
  final int prizePool;
  final int entryFee;
  final int slotsFilled;
  final int slotsTotal;
  final String startsIn;
  final TournamentStatus status;
  final Color badgeColor;
  final String mode; // Squad, Solo, Duo
  final int playersPerTeam;
  final String map;
  final String registrationEnds;
  final String tournamentStarts;
  final String type; // Paid / Free
  final String about;

  const Tournament({
    required this.id,
    required this.title,
    required this.game,
    required this.prizePool,
    required this.entryFee,
    required this.slotsFilled,
    required this.slotsTotal,
    required this.startsIn,
    required this.status,
    required this.badgeColor,
    this.mode = 'Squad',
    this.playersPerTeam = 4,
    this.map = 'Bermuda',
    this.registrationEnds = 'Today, 06:00 PM',
    this.tournamentStarts = 'Today, 08:00 PM',
    this.type = 'Paid',
    this.about =
        'Join the tournament and compete with the best players. Show your skills and win big prizes!',
  });
}

class GameFilter {
  final String label;
  const GameFilter(this.label);
}

class TxnHistory {
  final String title;
  final String dateTime;
  final int amount; // positive = credit, negative = debit
  final String status;
  final IconData icon;
  final Color color;

  const TxnHistory({
    required this.title,
    required this.dateTime,
    required this.amount,
    required this.status,
    required this.icon,
    required this.color,
  });
}

/// Mirrors backend `NotificationEventType` (app/models/notification.py).
/// Only the subset relevant to client-side routing is listed here.
enum NotificationEventType {
  general,
  tournamentCreated,
  tournamentUpdated,
  tournamentCancelled,
  registrationSuccessful,
  registrationCancelled,
  matchStarted,
  roomDetailsPublished,
  liveMatchStarted,
  winnerDeclared,
  prizeDistributed,
  walletCredited,
  walletDebited,
  adminBroadcast,
}

class NotificationItem {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final NotificationEventType eventType;

  /// Backend sends this inside `meta_data` (e.g. {"tournament_id": "..."}).
  /// Here we key it against the mock tournament id so tapping a
  /// tournament-related notification can open that tournament.
  final String? tournamentId;

  const NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.eventType = NotificationEventType.general,
    this.tournamentId,
  });
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    this.isCurrentUser = false,
  });
}

class MockData {
  MockData._();

  static const List<Tournament> tournaments = [
    Tournament(
      id: 't1',
      title: 'Rampage Cup',
      game: 'FREE FIRE',
      prizePool: 10000,
      entryFee: 100,
      slotsFilled: 76,
      slotsTotal: 100,
      startsIn: '02h 30m',
      status: TournamentStatus.upcoming,
      badgeColor: AppColors.danger,
      map: 'Bermuda',
      playersPerTeam: 4,
    ),
    Tournament(
      id: 't2',
      title: 'Booyah Battle',
      game: 'FREE FIRE',
      prizePool: 5000,
      entryFee: 50,
      slotsFilled: 45,
      slotsTotal: 50,
      startsIn: '01h 15m',
      status: TournamentStatus.upcoming,
      badgeColor: AppColors.danger,
    ),
    Tournament(
      id: 't3',
      title: 'Warriors League',
      game: 'BGMI',
      prizePool: 20000,
      entryFee: 200,
      slotsFilled: 30,
      slotsTotal: 100,
      startsIn: '05h 20m',
      status: TournamentStatus.upcoming,
      badgeColor: AppColors.warning,
    ),
    Tournament(
      id: 't4',
      title: 'Clash Squad Cup',
      game: 'FREE FIRE',
      prizePool: 5000,
      entryFee: 50,
      slotsFilled: 82,
      slotsTotal: 100,
      startsIn: 'LIVE',
      status: TournamentStatus.live,
      badgeColor: AppColors.danger,
    ),
    Tournament(
      id: 't5',
      title: 'BGMI Pro League',
      game: 'BGMI',
      prizePool: 10000,
      entryFee: 100,
      slotsFilled: 60,
      slotsTotal: 100,
      startsIn: '08h 00m',
      status: TournamentStatus.upcoming,
      badgeColor: AppColors.warning,
    ),
  ];

  static const List<String> gameFilters = [
    'All',
    'Free Fire',
    'BGMI',
    'CODM',
    'Valorant',
  ];

  static const List<TxnHistory> transactions = [
    TxnHistory(
      title: 'Added Money',
      dateTime: '20 May 2024, 10:30 AM',
      amount: 500,
      status: 'Success',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.success,
    ),
    TxnHistory(
      title: 'Tournament Entry',
      dateTime: '20 May 2024, 11:20 AM',
      amount: -100,
      status: 'Success',
      icon: Icons.shield_rounded,
      color: AppColors.danger,
    ),
    TxnHistory(
      title: 'Match Won Prize',
      dateTime: '19 May 2024, 09:15 PM',
      amount: 2000,
      status: 'Success',
      icon: Icons.emoji_events_rounded,
      color: AppColors.success,
    ),
    TxnHistory(
      title: 'Withdrawal Request',
      dateTime: '18 May 2024, 08:45 PM',
      amount: -500,
      status: 'Success',
      icon: Icons.arrow_circle_up_rounded,
      color: AppColors.danger,
    ),
  ];

  static const List<NotificationItem> notifications = [
    NotificationItem(
      title: 'Registration Successful',
      body: 'You have successfully registered for Rampage Cup.',
      time: '2m ago',
      icon: Icons.shield_rounded,
      color: AppColors.purple,
      eventType: NotificationEventType.registrationSuccessful,
      tournamentId: 't1',
    ),
    NotificationItem(
      title: 'Tournament Starting Soon',
      body: 'Rampage Cup will start in 30 minutes.',
      time: '25m ago',
      icon: Icons.lock_clock_rounded,
      color: AppColors.warning,
      eventType: NotificationEventType.tournamentUpdated,
      tournamentId: 't1',
    ),
    NotificationItem(
      title: 'Prize Credited',
      body: 'You have won ₹2,000 in Booyah Battle.',
      time: '1h ago',
      icon: Icons.emoji_events_rounded,
      color: AppColors.success,
      eventType: NotificationEventType.prizeDistributed,
      tournamentId: 't2',
    ),
    NotificationItem(
      title: 'Withdrawal Successful',
      body: '₹500 has been sent to your bank account.',
      time: '3h ago',
      icon: Icons.account_balance_rounded,
      color: AppColors.blue,
      eventType: NotificationEventType.walletDebited,
    ),
    NotificationItem(
      title: 'Team Invitation',
      body: 'You have been invited to join a team.',
      time: '5h ago',
      icon: Icons.group_add_rounded,
      color: AppColors.danger,
      eventType: NotificationEventType.general,
    ),
  ];

  /// Helper used by the UI to resolve a notification's tournamentId
  /// back to the full Tournament object (in the real app this would
  /// simply be a GET /tournaments/{id} call).
  static Tournament? findTournament(String? id) {
    if (id == null) return null;
    for (final t in tournaments) {
      if (t.id == id) return t;
    }
    return null;
  }

  static const List<LeaderboardEntry> leaderboard = [
    LeaderboardEntry(rank: 1, name: 'DARK_KILLER', points: 12560),
    LeaderboardEntry(rank: 2, name: 'ViperX', points: 11230),
    LeaderboardEntry(rank: 3, name: 'LEGEND_07', points: 10450),
    LeaderboardEntry(rank: 4, name: 'FireStorm', points: 9870),
    LeaderboardEntry(rank: 5, name: 'HeadHunter', points: 9230),
    LeaderboardEntry(rank: 45, name: 'Sudip', points: 4560, isCurrentUser: true),
  ];

  static const List<int> addMoneyOptions = [100, 200, 500, 1000, 2000, 5000, 10000];
}
