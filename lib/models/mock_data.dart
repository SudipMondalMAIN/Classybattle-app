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
}
