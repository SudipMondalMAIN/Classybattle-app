import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/leaderboard.dart';

/// Wraps app/api/v1/leaderboard_routes.py.
class LeaderboardService {
  final Dio _dio = ApiClient.instance.dio;

  /// Global top players, ordered by ranking_score (see LeaderboardService
  /// docstring in the backend for how ranking_score is computed).
  Future<List<PlayerStatistics>> topPlayers({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _dio.get('/leaderboard/players/top', queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final items = res.data['items'] as List;
      return items.map((e) => PlayerStatistics.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PlayerStatistics> getPlayerStatistics(String userId) async {
    try {
      final res = await _dio.get('/players/$userId/statistics');
      return PlayerStatistics.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PlayerStatistics>> searchPlayers(String q, {int page = 1, int pageSize = 20}) async {
    try {
      final res = await _dio.get('/leaderboard/players/search', queryParameters: {
        'q': q,
        'page': page,
        'page_size': pageSize,
      });
      final items = res.data['items'] as List;
      return items.map((e) => PlayerStatistics.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
