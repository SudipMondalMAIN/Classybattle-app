import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../models/leaderboard_model.dart';
import '../providers/home_providers.dart';
import '../providers/leaderboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';

/// Global player leaderboard, ranked by ranking_score
/// (GET /leaderboard/players/top). The current user's own row is
/// highlighted when it appears in the visible top players.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(topPlayersProvider);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(topPlayersProvider);
    final userAsync = ref.watch(currentUserProvider);
    final myUserId = userAsync.valueOrNull?.id;

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
                      'Leaderboard',
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
                  'Top players ranked by overall performance.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.purple,
                  backgroundColor: AppColors.background,
                  onRefresh: () => _refresh(ref),
                  child: playersAsync.when(
                    loading: () => const _CenteredLoader(),
                    error: (e, __) => _CenteredError(
                      onRetry: () => ref.invalidate(topPlayersProvider),
                    ),
                    data: (players) {
                      if (players.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(
                              child: Text(
                                'No ranked players yet.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: players.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = players[i];
                          final rank = p.currentRank ?? (i + 1);
                          return _PlayerRow(
                            player: p,
                            rank: rank,
                            isMe: myUserId != null && p.userId == myUserId,
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
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.rank,
    required this.isMe,
  });

  final PlayerStatsModel player;
  final int rank;
  final bool isMe;

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: isMe ? AppColors.purple.withValues(alpha: 0.7) : null,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: rank <= 3
                ? Icon(Icons.emoji_events_rounded, color: _rankColor, size: 22)
                : Text(
                    '#$rank',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.glassFillStrong,
            child: const Icon(Icons.person, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? 'You' : 'Player ${player.userId.substring(0, 8)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.matchesWon}/${player.matchesPlayed} wins · '
                  '${player.winRate.toStringAsFixed(0)}% win rate',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupees(player.prizeMoneyEarned),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'won',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ],
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
  const _CenteredError({required this.onRetry});

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
        const Center(
          child: Text(
            'Couldn\'t load the leaderboard.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
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
