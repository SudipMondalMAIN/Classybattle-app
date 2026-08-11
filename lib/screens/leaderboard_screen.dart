import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_exception.dart';
import '../models/leaderboard.dart';
import '../providers/auth_provider.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _leaderboardService = LeaderboardService();

  bool _loading = true;
  String? _error;
  List<PlayerStatistics> _players = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final players = await _leaderboardService.topPlayers(page: 1, pageSize: 50);
      if (!mounted) return;
      setState(() {
        _players = players;
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

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 14),
                  const Text('Leaderboard',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody(myUserId)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String? myUserId) {
    if (_loading) {
      return const SkeletonListPage(count: 8);
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 60, 18, 20),
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      );
    }
    if (_players.isEmpty) {
      return const Center(
        child: Text('No ranked players yet', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final top3 = _players.take(3).toList();
    final rest = _players.skip(3).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        children: [
          if (top3.length == 3) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _podium(top3[1], myUserId, height: 90, color: const Color(0xFFB0B0C0)),
                const SizedBox(width: 10),
                _podium(top3[0], myUserId, height: 115, color: AppColors.gold, crown: true),
                const SizedBox(width: 10),
                _podium(top3[2], myUserId, height: 75, color: const Color(0xFFCD7F32)),
              ],
            ),
            const SizedBox(height: 22),
          ],
          const Row(
            children: [
              SizedBox(width: 36, child: Text('Rank', style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
              SizedBox(width: 10),
              Expanded(child: Text('Player', style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
              Text('Score', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          ...(top3.length == 3 ? rest : _players).map((e) => _rankTile(e, myUserId)),
        ],
      ),
    );
  }

  String _shortName(PlayerStatistics p) => 'Player #${p.userId.substring(0, 6).toUpperCase()}';

  void _openProfile(PlayerStatistics p, String? myUserId) {
    if (p.userId == myUserId) return; // tapping your own row shouldn't open the report flow
    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: p.userId)));
  }

  Widget _podium(PlayerStatistics e, String? myUserId, {required double height, required Color color, bool crown = false}) {
    final rank = e.currentRank ?? 0;
    return GestureDetector(
      onTap: () => _openProfile(e, myUserId),
      child: Column(
        children: [
          if (crown) const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
          Container(
            width: 54,
            height: 54,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              color: AppColors.surface,
            ),
            child: Icon(Icons.person_rounded, color: color, size: 28),
          ),
          SizedBox(
            width: 80,
            child: Text(_shortName(e),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          Text(e.rankingScore.toStringAsFixed(0), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            width: 74,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.08)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text('#$rank', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _rankTile(PlayerStatistics e, String? myUserId) {
    final isCurrentUser = e.userId == myUserId;
    return GestureDetector(
      onTap: () => _openProfile(e, myUserId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isCurrentUser ? AppColors.primaryGradient : null,
          color: isCurrentUser ? null : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isCurrentUser ? Colors.transparent : AppColors.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text('${e.currentRank ?? '-'}',
                  style: TextStyle(
                      color: isCurrentUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: Icon(Icons.person_rounded, color: isCurrentUser ? Colors.white : AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(isCurrentUser ? 'You' : _shortName(e),
                  style: TextStyle(
                      color: isCurrentUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            Text(e.rankingScore.toStringAsFixed(0),
                style: TextStyle(
                    color: isCurrentUser ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
