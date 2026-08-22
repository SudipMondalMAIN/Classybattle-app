import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/social_model.dart';
import 'home_service.dart' show UnauthenticatedException;

class SocialService {
  SocialService(this._dio);

  final Dio _dio;

  /// GET /social/profiles/{user_id} -- public profile for the
  /// leaderboard "tap a player" flow. Works anonymously too (backend
  /// treats missing/invalid token as an anonymous viewer), but we
  /// require login in the app so friend actions have a viewer.
  Future<PublicProfileModel> fetchProfile(String userId) async {
    try {
      final res = await _dio.get('/social/profiles/$userId');
      return PublicProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /social/friends/requests -- send a friend request.
  Future<FriendshipModel> sendFriendRequest(String addresseeId) async {
    try {
      final res = await _dio.post(
        '/social/friends/requests',
        data: {'addressee_id': addresseeId},
      );
      return FriendshipModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /social/friends/requests/{friendship_id}/accept -- accept an
  /// incoming friend request directly (e.g. from the public profile
  /// screen's Accept/Reject buttons).
  Future<FriendshipModel> acceptFriendRequest(String friendshipId) async {
    try {
      final res = await _dio.post('/social/friends/requests/$friendshipId/accept');
      return FriendshipModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /social/friends/requests/{friendship_id}/reject -- reject an
  /// incoming friend request directly.
  Future<FriendshipModel> rejectFriendRequest(String friendshipId) async {
    try {
      final res = await _dio.post('/social/friends/requests/$friendshipId/reject');
      return FriendshipModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final socialService = SocialService(ApiClient.instance.dio);
