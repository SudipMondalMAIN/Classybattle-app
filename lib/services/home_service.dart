import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/banner_model.dart';
import '../models/game_model.dart';
import '../models/home_category_box_model.dart';
import '../models/tournament_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

/// Thrown when a call needed a logged-in user but there's no valid
/// token. Callers use this to show a "log in" state instead of a
/// generic error.
class UnauthenticatedException implements Exception {}

class HomeService {
  HomeService(this._dio);

  final Dio _dio;

  /// GET /banners -- public, active banners for the home hero carousel.
  Future<List<BannerModel>> fetchBanners() async {
    final res = await _dio.get('/banners');
    final data = res.data as List;
    return data
        .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /home-boxes -- public, active home-screen category boxes
  /// (Solo / Squad / Custom Tournament tap boxes), in sort order.
  Future<List<HomeCategoryBoxModel>> fetchHomeCategoryBoxes() async {
    final res = await _dio.get('/home-boxes');
    final data = res.data as List;
    return data
        .map((e) => HomeCategoryBoxModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /games -- used to resolve tournament.gameId -> display name.
  Future<List<GameModel>> fetchGames() async {
    final res = await _dio.get('/games');
    final data = res.data as List;
    return data
        .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /tournaments with a status alias ("ongoing" | "upcoming") and
  /// optional is_featured filter. Public endpoint, no auth required.
  Future<List<TournamentModel>> fetchTournaments({
    required String status,
    bool? isFeatured,
    int pageSize = 20,
  }) async {
    final res = await _dio.get(
      '/tournaments',
      queryParameters: {
        'status': status,
        'page_size': pageSize,
        if (isFeatured != null) 'is_featured': isFeatured,
      },
    );
    final items = res.data['items'] as List;
    return items
        .map((e) => TournamentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /wallet -- requires auth; surfaces as [UnauthenticatedException]
  /// when there's no session so the UI can show a login prompt instead
  /// of a fake balance.
  Future<WalletModel> fetchWallet() async {
    try {
      final res = await _dio.get('/wallet');
      return WalletModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// GET /users/me -- requires auth; same unauthenticated handling as
  /// [fetchWallet].
  Future<UserModel> fetchMe() async {
    try {
      final res = await _dio.get('/users/me');
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final homeService = HomeService(ApiClient.instance.dio);
