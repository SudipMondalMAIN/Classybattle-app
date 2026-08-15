import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/custom_match_claim_model.dart';
import '../models/game_mode_model.dart';
import '../models/map_model.dart';
import '../models/participant_model.dart';
import '../models/participant_public_model.dart';
import '../models/prize_pool_model.dart';
import '../models/tournament_detail_model.dart';
import '../models/tournament_model.dart';
import 'home_service.dart' show UnauthenticatedException;

/// Thrown when a self-declared custom-tournament result submission fails
/// for a known, user-facing reason (missing proof, room not live yet,
/// already resolved, etc).
class SubmitResultException implements Exception {
  SubmitResultException(this.message);
  final String message;
}

/// Thrown when POST join fails for a known, user-facing reason (e.g.
/// insufficient wallet balance, missing game profile, already joined).
class JoinTournamentException implements Exception {
  JoinTournamentException(this.message);
  final String message;
}

/// Thrown when POST /tournaments/custom fails for a known, user-facing
/// reason (validation error, duplicate title, etc).
class CreateTournamentException implements Exception {
  CreateTournamentException(this.message);
  final String message;
}

class PagedResult<T> {
  PagedResult(this.items, this.total);
  final List<T> items;
  final int total;
}

class TournamentService {
  TournamentService(this._dio);

  final Dio _dio;

  /// GET /tournaments -- list with optional status alias
  /// (all|ongoing|upcoming|past), free-text search, game filter and
  /// category filter (solo|squad). Pass [isCustom]=true to list
  /// user-hosted Custom Tournaments instead -- those never have a
  /// solo/squad category, so `category` is ignored when set.
  Future<PagedResult<TournamentModel>> fetchTournaments({
    String? status,
    String? search,
    String? gameId,
    String? category,
    bool? isCustom,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get(
      '/tournaments',
      queryParameters: {
        if (status != null && status != 'all') 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (gameId != null) 'game_id': gameId,
        if (isCustom == true)
          'is_custom': true
        else if (category != null)
          'category': category,
        'page': page,
        'page_size': pageSize,
        // Chronological order (10:00, then 10:30, then 11:00...) --
        // NOT created_at, which reflects batch-generation order and
        // shuffles slots out of time order.
        'sort_by': 'starts_at',
        'sort_order': 'asc',
      },
    );
    final items = (res.data['items'] as List)
        .map((e) => TournamentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (res.data['total'] as num?)?.toInt() ?? items.length;
    return PagedResult(items, total);
  }

  /// GET /tournaments/{id} -- full detail for the Tournament Details screen.
  Future<TournamentDetailModel> fetchTournamentDetail(String id) async {
    final res = await _dio.get('/tournaments/$id');
    return TournamentDetailModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /tournaments/{id}/publish-room -- host (or admin) sets
  /// room_id/room_password, tournament auto-flips to LIVE.
  Future<TournamentDetailModel> publishRoom({
    required String tournamentId,
    required String roomId,
    required String roomPassword,
  }) async {
    try {
      final res = await _dio.post(
        '/tournaments/$tournamentId/publish-room',
        data: {'room_id': roomId, 'room_password': roomPassword},
      );
      return TournamentDetailModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw SubmitResultException(
        detail is String ? detail : 'Could not publish room details.',
      );
    }
  }

  /// GET /game-modes/{id}
  Future<GameModeModel?> fetchGameMode(String? id) async {
    if (id == null) return null;
    try {
      final res = await _dio.get('/game-modes/$id');
      return GameModeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  /// GET /maps/{id}
  Future<MapModel?> fetchMap(String? id) async {
    if (id == null) return null;
    try {
      final res = await _dio.get('/maps/$id');
      return MapModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  /// GET /tournaments/{id}/prize-pool -- 404 when the organizer hasn't
  /// configured one yet, which is a real, valid state (not an error).
  Future<PrizePoolModel?> fetchPrizePool(String tournamentId) async {
    try {
      final res = await _dio.get('/tournaments/$tournamentId/prize-pool');
      return PrizePoolModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET /tournaments/{id}/registration -- the current user's own
  /// registration for this tournament, or null if they haven't joined
  /// (404) or aren't logged in (401).
  Future<ParticipantModel?> fetchMyRegistration(String tournamentId) async {
    try {
      final res = await _dio.get('/tournaments/$tournamentId/registration');
      return ParticipantModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }

  /// GET /tournaments/{id}/participants -- full public roster for the
  /// Tournament Details screen: every participant's avatar/name/in-game
  /// nickname+uid, and (once the tournament has results) their
  /// rank/win/prize too. Paginated; page_size 100 covers the vast
  /// majority of tournaments in one call.
  Future<PagedResult<ParticipantPublicModel>> fetchTournamentParticipants(
    String tournamentId, {
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final res = await _dio.get(
        '/tournaments/$tournamentId/participants',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final items = (res.data['items'] as List)
          .map(
            (e) => ParticipantPublicModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      final total = (res.data['total'] as num?)?.toInt() ?? items.length;
      return PagedResult(items, total);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /tournaments/{id}/join/solo -- instant join, wallet-debited.
  Future<void> joinSolo(String tournamentId) async {
    try {
      await _dio.post('/tournaments/$tournamentId/join/solo', data: {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw JoinTournamentException(
        detail?.toString() ?? 'Could not join this tournament right now.',
      );
    }
  }

  /// POST /tournaments/custom -- user-hosted "Custom Tournament" creation.
  /// Host only sets entry fee + player count; prize_pool is computed by
  /// the backend (never trusted from the client). Goes live immediately,
  /// no admin approval.
  Future<TournamentModel> createCustomTournament({
    required String title,
    required String gameId,
    required double entryFee,
    required int maxPlayers,
    String? modeId,
    String? mapId,
    String registrationMode = 'solo',
    int teamSize = 1,
    int? maxTeams,
  }) async {
    try {
      final res = await _dio.post(
        '/tournaments/custom',
        data: {
          'title': title,
          'game_id': gameId,
          'entry_fee': entryFee,
          'max_players': maxPlayers,
          if (modeId != null) 'mode_id': modeId,
          if (mapId != null) 'map_id': mapId,
          'registration_mode': registrationMode,
          'team_size': teamSize,
          if (maxTeams != null) 'max_teams': maxTeams,
        },
      );
      return TournamentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final data = e.response?.data;
      String message = 'Could not create the tournament. Please try again.';
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            message = first['msg'].toString();
          }
        }
      }
      throw CreateTournamentException(message);
    }
  }

  /// GET /users/me/registrations -- the current user's real join
  /// history, used for the "My Tournaments" tab and the Joined stat.
  Future<PagedResult<ParticipantModel>> fetchMyRegistrations({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final res = await _dio.get(
        '/users/me/registrations',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final items = (res.data['items'] as List)
          .map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (res.data['total'] as num?)?.toInt() ?? items.length;
      return PagedResult(items, total);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// GET /prize-payouts/me -- real payout history, used to compute the
  /// "Won" and "Total Winnings" stats from actual paid-out prizes.
  Future<List<PrizePayoutModel>> fetchMyPrizePayouts() async {
    try {
      final res = await _dio.get(
        '/prize-payouts/me',
        queryParameters: {'page_size': 100},
      );
      return (res.data['items'] as List)
          .map((e) => PrizePayoutModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// ---- Custom Tournament self-declared results (1v1 only) ----
  ///
  /// Claiming "loss" needs no proof and instantly pays the opponent.
  /// Claiming "win" requires a proof screenshot -- upload it first via
  /// [uploadResultProof], then pass the returned url here.

  /// POST /tournaments/{id}/custom-result/proof -- uploads a win-claim
  /// screenshot, returns its URL.
  Future<String> uploadResultProof(String tournamentId, File screenshot) async {
    try {
      final fileName = screenshot.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(screenshot.path, filename: fileName),
      });
      final res = await _dio.post(
        '/tournaments/$tournamentId/custom-result/proof',
        data: formData,
      );
      return res.data['message'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw SubmitResultException(
        detail?.toString() ?? 'Couldn\'t upload the screenshot. Try again.',
      );
    }
  }

  /// POST /tournaments/{id}/custom-result -- submit "win" (with
  /// [proofUrl]) or "loss" (no proof needed).
  Future<CustomMatchClaimPairModel> submitCustomResult(
    String tournamentId, {
    required String outcome,
    String? proofUrl,
  }) async {
    try {
      final res = await _dio.post(
        '/tournaments/$tournamentId/custom-result',
        data: {
          'outcome': outcome,
          if (proofUrl != null) 'proof_url': proofUrl,
        },
      );
      return CustomMatchClaimPairModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw SubmitResultException(
        detail?.toString() ?? 'Couldn\'t submit the result. Try again.',
      );
    }
  }

  /// GET /tournaments/{id}/custom-result -- current claim state for
  /// both players.
  Future<CustomMatchClaimPairModel?> fetchCustomResult(String tournamentId) async {
    try {
      final res = await _dio.get('/tournaments/$tournamentId/custom-result');
      return CustomMatchClaimPairModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      // Not a participant / not a custom 1v1 tournament -- nothing to show.
      if (e.response?.statusCode == 403 || e.response?.statusCode == 400) return null;
      rethrow;
    }
  }
}

final tournamentService = TournamentService(ApiClient.instance.dio);
