import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../core/api_exception.dart';
import 'auth/auth_widgets.dart';
import 'tournaments/game_profile_dialog.dart';
import '../widgets/skeleton.dart';

/// Lets the user review and edit the game profiles they've already saved
/// (created automatically the first time they joined each game's tournament).
class GameProfilesScreen extends StatefulWidget {
  const GameProfilesScreen({super.key});

  @override
  State<GameProfilesScreen> createState() => _GameProfilesScreenState();
}

class _GameProfilesScreenState extends State<GameProfilesScreen> {
  final _service = GameService();
  bool _loading = true;
  List<Game> _games = [];
  List<UserGameProfile> _profiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final games = await _service.listGames();
      final profiles = await _service.myGameProfiles();
      setState(() {
        _games = games;
        _profiles = profiles;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _edit(Game game, UserGameProfile profile) async {
    final updated = await showGameProfileDialog(
      context,
      game: game,
      existing: profile,
    );
    if (updated != null) {
      setState(() {
        _profiles = [
          for (final p in _profiles)
            if (p.gameId == game.id) updated else p,
        ];
      });
    }
  }

  Future<void> _addNew() async {
    final existingGameIds = _profiles.map((p) => p.gameId).toSet();
    final available = _games
        .where((g) => !existingGameIds.contains(g.id))
        .toList();

    if (available.isEmpty) {
      showAuthSnack(
        context,
        'You already have a profile for every game',
        isError: false,
      );
      return;
    }

    final chosen = await showModalBottomSheet<Game>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a game',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...available.map(
                (g) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.sports_esports_rounded,
                    color: AppColors.purple,
                  ),
                  title: Text(
                    g.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, g),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    final created = await showGameProfileDialog(context, game: chosen);
    if (created != null && mounted) {
      setState(() => _profiles = [..._profiles, created]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      appBar: AppBar(
        backgroundColor: AppColors.bgBottom,
        title: const Text(
          'Game Profiles',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              onPressed: _addNew,
              icon: const Icon(
                Icons.add_circle_rounded,
                color: AppColors.purple,
              ),
              tooltip: 'Add Game Profile',
            ),
        ],
      ),
      body: _loading
          ? const SkeletonListPage(count: 4, leadingCircle: false)
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : _profiles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No game profiles saved yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _addNew,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Add Game Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: _profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final profile = _profiles[i];
                final game = _games.firstWhere(
                  (g) => g.id == profile.gameId,
                  orElse: () => Game(
                    id: profile.gameId,
                    name: 'Unknown Game',
                    slug: '',
                    isActive: true,
                    profileSchema: [],
                  ),
                );
                final summary = profile.data.values.join(' · ');
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _edit(game, profile),
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
