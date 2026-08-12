import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../models/game_profile_model.dart';
import '../providers/home_providers.dart';
import '../providers/tournament_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/game_profile/add_game_profile_sheet.dart';

/// Lists every active game and, for each, whether the user has saved
/// an in-game profile (nickname/UID etc). Tapping a game opens the
/// Add/Edit sheet -- this is the one place a user can manage their
/// profiles outside of the join flow.
class GameProfilesScreen extends ConsumerWidget {
  const GameProfilesScreen({super.key});

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    GameModel game,
    GameProfileModel? existing,
  ) async {
    final saved = await AddGameProfileSheet.show(
      context,
      game,
      existingProfile: existing,
    );
    if (saved == true) {
      ref.invalidate(myGameProfilesProvider);
      ref.invalidate(hasGameProfileProvider(game.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'Game profile saved.'
                  : 'Game profile updated.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(allGamesProvider);
    ref.invalidate(myGameProfilesProvider);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(allGamesProvider);
    final profilesAsync = ref.watch(myGameProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientTop,
              AppColors.backgroundGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Game Profiles',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Save your in-game nickname and UID for each game -- '
                  'you need this before joining a tournament.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.purple,
                  backgroundColor: AppColors.background,
                  onRefresh: () => _refresh(ref),
                  child: gamesAsync.when(
                    loading: () => const _CenteredLoader(),
                    error: (e, __) => _CenteredError(
                      message: 'Couldn\'t load games.',
                      onRetry: () => ref.invalidate(allGamesProvider),
                    ),
                    data: (games) {
                      if (games.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(
                              child: Text(
                                'No games available yet.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        );
                      }

                      final profilesByGameId = {
                        for (final p in profilesAsync.valueOrNull ?? const <GameProfileModel>[])
                          p.gameId: p,
                      };
                      final profilesLoading = profilesAsync.isLoading;

                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: games.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final game = games[i];
                          final existing = profilesByGameId[game.id];
                          final hasProfile = existing != null;

                          return GlassContainer(
                            borderRadius: 18,
                            padding: EdgeInsets.zero,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: profilesLoading
                                  ? null
                                  : () => _openSheet(context, ref, game, existing),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    _GameIcon(game: game),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            game.name,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (profilesLoading)
                                            const Text(
                                              'Checking...',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            )
                                          else if (hasProfile)
                                            Text(
                                              _summarize(existing),
                                              style: const TextStyle(
                                                color: AppColors.success,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          else
                                            const Text(
                                              'Not set up yet',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (!profilesLoading)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasProfile
                                              ? AppColors.glassFillStrong
                                              : AppColors.purple
                                                  .withValues(alpha: 0.85),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          hasProfile ? 'Edit' : 'Add',
                                          style: TextStyle(
                                            color: hasProfile
                                                ? AppColors.textPrimary
                                                : Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summarize(GameProfileModel profile) {
    if (profile.data.isEmpty) return 'Set up';
    return profile.data.values.map((v) => v.toString()).join(' · ');
  }
}

class _GameIcon extends StatelessWidget {
  const _GameIcon({required this.game});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final url = game.iconUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        color: AppColors.glassFillStrong,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.purpleSoft,
                ),
              )
            : const Icon(Icons.sports_esports_rounded, color: AppColors.purpleSoft),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator(color: AppColors.purpleSoft)),
      ],
    );
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        const Center(
          child: Icon(Icons.error_outline_rounded, color: AppColors.textMuted, size: 36),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        const SizedBox(height: 14),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purpleSoft,
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
