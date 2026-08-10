import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/tournament.dart';
import '../models/participant.dart';

class TournamentService {
  final Dio _dio = ApiClient.instance.dio;

  /// [status] accepts backend aliases: "upcoming" | "ongoing" | "past",
  /// or exact enum values (scheduled/live/completed/cancelled).
  Future<List<Tournament>> list({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
    bool? isFeatured,
  }) async {
    try {
      final res = await _dio.get('/tournaments', queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isFeatured != null) 'is_featured': isFeatured,
      });
      final items = res.data['items'] as List;
      return items.map((e) => Tournament.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Tournament> getById(String tournamentId) async {
    try {
      final res = await _dio.get('/tournaments/$tournamentId');
      return Tournament.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Joins a tournament using a saved in-game profile.
  /// [registrationType] "solo" | "team_invite" | "auto_random".
  Future<Participant> register({
    required String tournamentId,
    required String gameProfileId,
    String registrationType = 'solo',
    String? teamName,
  }) async {
    try {
      final res = await _dio.post(
        '/tournaments/$tournamentId/register',
        data: {
          'game_profile_id': gameProfileId,
          'registration_type': registrationType,
          if (teamName != null) 'team_name': teamName,
        },
        // Prevents double-join/double-charge on a retried network call.
        options: Options(headers: {'Idempotency-Key': _idempotencyKey(tournamentId)}),
      );
      return Participant.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Participant> cancelRegistration(String tournamentId) async {
    try {
      final res = await _dio.post('/tournaments/$tournamentId/cancel');
      return Participant.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Participant?> getMyRegistration(String tournamentId) async {
    try {
      final res = await _dio.get('/tournaments/$tournamentId/registration');
      return Participant.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  /// The current user's full join history — powers "My Tournaments".
  Future<List<Participant>> myRegistrations({int page = 1, int pageSize = 20, String? status}) async {
    try {
      final res = await _dio.get('/users/me/registrations', queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null) 'status': status,
      });
      final items = res.data['items'] as List;
      return items.map((e) => Participant.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  String _idempotencyKey(String tournamentId) =>
      'join-$tournamentId-${DateTime.now().millisecondsSinceEpoch ~/ 5000}';
}
