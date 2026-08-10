import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/game.dart';

class GameService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Game>> listGames() async {
    try {
      final res = await _dio.get('/games');
      return (res.data as List).map((e) => Game.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// All of the current user's saved in-game profiles, one per game
  /// they've ever filled in. Used to skip the "add game profile" popup
  /// on repeat joins of the same game.
  Future<List<UserGameProfile>> myGameProfiles() async {
    try {
      final res = await _dio.get('/games/profiles/me');
      return (res.data as List).map((e) => UserGameProfile.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserGameProfile> createProfile({
    required String gameId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _dio.post('/games/profiles', data: {
        'game_id': gameId,
        'data': data,
      });
      return UserGameProfile.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserGameProfile> updateProfile({
    required String gameId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _dio.patch('/games/$gameId/profile', data: {'data': data});
      return UserGameProfile.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
