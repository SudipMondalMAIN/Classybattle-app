import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';

/// Top 50 players, globally ranked by ranking_score.
final topPlayersProvider = FutureProvider<List<PlayerStatsModel>>((ref) {
  return leaderboardService.fetchTopPlayers(pageSize: 50);
});
