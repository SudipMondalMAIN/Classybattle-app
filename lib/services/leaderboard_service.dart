import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  LeaderboardService(this._dio);

  final Dio _dio;

  /// GET /leaderboard/players/top -- global player leaderboard, ranked
  /// by ranking_score. Public endpoint, no auth required.
  Future<List<PlayerStatsModel>> fetchTopPlayers({
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get(
      '/leaderboard/players/top',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final items = (res.data as Map)['items'] as List;
    return items
        .map((e) => PlayerStatsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final leaderboardService = LeaderboardService(ApiClient.instance.dio);
