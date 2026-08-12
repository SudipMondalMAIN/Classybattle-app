import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/game_profile_model.dart';
import 'home_service.dart' show UnauthenticatedException;

/// Thrown when creating/updating a game profile fails for a known,
/// user-facing reason (e.g. missing required field).
class GameProfileException implements Exception {
  GameProfileException(this.message);
  final String message;
}

class GameProfileService {
  GameProfileService(this._dio);

  final Dio _dio;

  /// GET /games/profiles/me -- all saved game profiles for the current
  /// user, one per game they've set up.
  Future<List<GameProfileModel>> fetchMyGameProfiles() async {
    try {
      final res = await _dio.get('/games/profiles/me');
      final data = res.data as List;
      return data
          .map((e) => GameProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /games/profiles -- create the user's in-game identity for a
  /// game (nickname/UID etc, shape defined by Game.profile_schema).
  /// Required before joining any tournament for that game.
  Future<GameProfileModel> createGameProfile(
    String gameId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post(
        '/games/profiles',
        data: {'game_id': gameId, 'data': data},
      );
      return GameProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw GameProfileException(
        detail?.toString() ?? 'Could not save your game profile right now.',
      );
    }
  }

  /// PATCH /games/{game_id}/profile -- update an existing profile's
  /// saved fields.
  Future<GameProfileModel> updateGameProfile(
    String gameId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.patch(
        '/games/$gameId/profile',
        data: {'data': data},
      );
      return GameProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw GameProfileException(
        detail?.toString() ?? 'Could not update your game profile right now.',
      );
    }
  }
}

final gameProfileService = GameProfileService(ApiClient.instance.dio);
