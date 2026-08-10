import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/mock_data.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final top3 = MockData.leaderboard.where((e) => e.rank <= 3).toList();
    final rest = MockData.leaderboard.where((e) => e.rank > 3).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  children: List.generate(3, (i) {
                    final labels = ['Global', 'Friends', 'Region'];
                    final selected = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _podium(top3[1], height: 90, color: const Color(0xFFB0B0C0)),
                const SizedBox(width: 10),
                _podium(top3[0], height: 115, color: AppColors.gold, crown: true),
                const SizedBox(width: 10),
                _podium(top3[2], height: 75, color: const Color(0xFFCD7F32)),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                children: [
                  const Row(
                    children: [
                      SizedBox(width: 36, child: Text('Rank', style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
                      SizedBox(width: 10),
                      Expanded(child: Text('Player', style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
                      Text('Points', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...rest.map((e) => _rankTile(e)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _podium(LeaderboardEntry e, {required double height, required Color color, bool crown = false}) {
    return GestureDetector(
      onTap: () => _openProfile(e),
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
          child: Text(e.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        Text('${e.points}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
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
          child: Text('#${e.rank}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ),
      ],
      ),
    );
  }

  void _openProfile(LeaderboardEntry e) {
    if (e.isCurrentUser) return; // tapping your own row shouldn't open the report flow
    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(entry: e)));
  }

  Widget _rankTile(LeaderboardEntry e) {
    return GestureDetector(
      onTap: () => _openProfile(e),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: e.isCurrentUser ? AppColors.primaryGradient : null,
        color: e.isCurrentUser ? null : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: e.isCurrentUser ? Colors.transparent : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('${e.rank}',
                style: TextStyle(
                    color: e.isCurrentUser ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Icon(Icons.person_rounded, color: e.isCurrentUser ? Colors.white : AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(e.name,
                style: TextStyle(
                    color: e.isCurrentUser ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Text('${e.points}',
              style: TextStyle(
                  color: e.isCurrentUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
      ),
    );
  }
}
