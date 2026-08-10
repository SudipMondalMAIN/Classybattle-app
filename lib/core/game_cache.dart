import '../models/game.dart';
import '../services/game_service.dart';

/// Tiny in-memory cache for the (rarely-changing) games list, so every
/// screen that needs to resolve a tournament's game_id -> game name/icon
/// doesn't have to re-hit `/games` on every build.
class GameCache {
  GameCache._();
  static final GameCache instance = GameCache._();

  final GameService _service = GameService();
  List<Game>? _games;

  Future<List<Game>> all({bool forceRefresh = false}) async {
    if (_games == null || forceRefresh) {
      _games = await _service.listGames();
    }
    return _games!;
  }

  /// Returns a lookup map of game_id -> Game, fetching/caching as needed.
  Future<Map<String, Game>> byId({bool forceRefresh = false}) async {
    final games = await all(forceRefresh: forceRefresh);
    return {for (final g in games) g.id: g};
  }
}
