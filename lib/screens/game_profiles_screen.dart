import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../core/api_exception.dart';
import 'auth/auth_widgets.dart';
import 'tournaments/game_profile_dialog.dart';

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
    final updated = await showGameProfileDialog(context, game: game, existing: profile);
    if (updated != null) {
      setState(() {
        _profiles = [
          for (final p in _profiles) if (p.gameId == game.id) updated else p,
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      appBar: AppBar(
        backgroundColor: AppColors.bgBottom,
        title: const Text('Game Profiles', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : _error != null
              ? Center(
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
              : _profiles.isEmpty
                  ? const Center(
                      child: Text(
                        'Ekhono kono game profile save koroni.\nEkta tournament join korle automatic add hobe.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
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
                              profileSchema: []),
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
                                    Text(game.name,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(summary,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _edit(game, profile),
                                icon: const Icon(Icons.edit_rounded, color: AppColors.cyan),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
