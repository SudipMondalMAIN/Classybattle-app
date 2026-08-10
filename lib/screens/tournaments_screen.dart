import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/api_exception.dart';
import '../core/game_cache.dart';
import '../models/tournament.dart';
import '../models/game.dart';
import '../services/tournament_service.dart';
import 'auth/auth_widgets.dart';
import 'tournament_detail_screen.dart';
import 'tournaments/join_tournament_flow.dart';
import '../widgets/common.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  final _tournamentService = TournamentService();

  String? _gameId; // null = All
  int _tabIndex = 0; // 0 upcoming, 1 live, 2 completed
  static const _statusForTab = ['upcoming', 'ongoing', 'past'];

  bool _loading = true;
  String? _error;
  List<Tournament> _tournaments = [];
  List<Game> _games = [];
  Map<String, Game> _gamesById = {};

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final games = await GameCache.instance.all();
      final list = await _tournamentService.list(
        status: _statusForTab[_tabIndex],
        gameId: _gameId,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _games = games;
        _gamesById = {for (final g in games) g.id: g};
        _tournaments = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _gameName(String gameId) => _gamesById[gameId]?.name ?? 'Unknown';

  Future<void> _join(Tournament t) async {
    final participant = await runJoinTournamentFlow(context, tournamentId: t.id, gameId: t.gameId);
    if (participant != null) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              children: [
                const Text('Tournaments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const Spacer(),
                _iconBtn(Icons.search_rounded, onTap: _showSearchDialog),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: _games.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final label = i == 0 ? 'All' : _games[i - 1].name;
                final gameId = i == 0 ? null : _games[i - 1].id;
                final selected = gameId == _gameId;
                return GestureDetector(
                  onTap: () {
                    setState(() => _gameId = gameId);
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(label,
                        style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  final labels = ['Upcoming', 'Live', 'Completed'];
                  final selected = i == _tabIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _tabIndex = i);
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.primaryGradient : null,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Text(labels[i],
                            style: TextStyle(
                                color: selected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_tournaments.isEmpty) {
      return const Center(
        child: Text('No tournaments found', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: _tournaments.length,
        itemBuilder: (context, i) {
          final t = _tournaments[i];
          return TournamentListCard(
            t: t,
            gameName: _gameName(t.gameId),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id))).then((_) => _load()),
            onJoin: () => _join(t),
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Search Tournaments', style: TextStyle(color: AppColors.textPrimary)),
        content: AuthTextField(controller: _searchController, label: 'Title'),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
              _load();
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _load();
            },
            child: const Text('Search', style: TextStyle(color: AppColors.purple)),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      );
}
