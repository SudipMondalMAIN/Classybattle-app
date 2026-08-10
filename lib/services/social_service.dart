import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/social.dart';

/// Wraps app/api/v1/social_routes.py (profiles/friends/follow) and the
/// player-report endpoint from app/api/v1/moderation_routes.py.
class SocialService {
  final Dio _dio = ApiClient.instance.dio;

  Future<PlayerProfile> getProfile(String userId) async {
    try {
      final res = await _dio.get('/social/profiles/$userId');
      return PlayerProfile.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PlayerProfile> getMyProfile() async {
    try {
      final res = await _dio.get('/social/profiles/me');
      return PlayerProfile.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> follow(String userId) async {
    try {
      await _dio.post('/social/follow', data: {'user_id': userId});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unfollow(String userId) async {
    try {
      await _dio.delete('/social/follow/$userId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Sends a friend request. [addresseeId] must be the target user's id.
  Future<void> sendFriendRequest(String addresseeId) async {
    try {
      await _dio.post('/social/friends/requests', data: {'addressee_id': addresseeId});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Reports a player. Backend: POST /reports with target_type="player"
  /// (app/models/moderation.py — Report / ReportTargetType / ReportReason).
  Future<void> reportPlayer({
    required String targetUserId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      await _dio.post('/reports', data: {
        'target_type': 'player',
        'target_id': targetUserId,
        'reason': reason.value,
        if (description != null && description.isNotEmpty) 'description': description,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
