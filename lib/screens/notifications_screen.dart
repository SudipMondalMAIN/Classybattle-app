import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/mock_data.dart';
import 'tournament_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text('Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                itemCount: MockData.notifications.length,
                itemBuilder: (context, i) => _NotifTile(
                  item: MockData.notifications[i],
                  onTap: () => _handleTap(context, MockData.notifications[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tapping a notification that carries a tournament_id (registration,
  /// tournament updates, live match, prize etc.) opens that tournament.
  /// Non-tournament notifications (wallet, team, admin broadcast) just
  /// stay on this screen — mirrors how the backend's `meta_data` field
  /// only carries a tournament_id for tournament-related event_types.
  void _handleTap(BuildContext context, NotificationItem item) {
    final tournament = MockData.findTournament(item.tournamentId);
    if (tournament != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: tournament)),
      );
    }
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;
  const _NotifTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    Text(item.time, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
