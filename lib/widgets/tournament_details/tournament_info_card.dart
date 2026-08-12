import 'package:flutter/material.dart';
import '../../models/game_mode_model.dart';
import '../../models/game_model.dart';
import '../../models/map_model.dart';
import '../../models/tournament_detail_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class _InfoField {
  final IconData icon;
  final String label;
  final String value;
  const _InfoField(this.icon, this.label, this.value);
}

class TournamentInfoCard extends StatelessWidget {
  const TournamentInfoCard({
    super.key,
    required this.tournament,
    required this.game,
    required this.gameMode,
    required this.map,
  });

  final TournamentDetailModel tournament;
  final GameModel? game;
  final GameModeModel? gameMode;
  final MapModel? map;

  @override
  Widget build(BuildContext context) {
    final registrationTypeLabel = switch (tournament.registrationMode) {
      'team_invite' => 'Team (Invite)',
      'auto_random' => 'Team (Random)',
      _ => 'Solo',
    };

    // Only real fields the backend actually has -- no invented
    // perspective/region/version values.
    final fields = <_InfoField>[
      if (game != null) _InfoField(Icons.sports_esports_outlined, 'Game', game!.name),
      _InfoField(Icons.auto_awesome_outlined, 'Type', registrationTypeLabel),
      if (gameMode != null)
        _InfoField(Icons.groups_2_outlined, 'Game Mode', gameMode!.name),
      _InfoField(Icons.people_outline, 'Max Players', '${tournament.maxPlayers}'),
      if (tournament.registrationMode != 'solo')
        _InfoField(Icons.group_work_outlined, 'Team Size', '${tournament.teamSize}'),
      if (map != null) _InfoField(Icons.map_outlined, 'Map', map!.name),
      if (tournament.organizer.isNotEmpty)
        _InfoField(Icons.badge_outlined, 'Organizer', tournament.organizer),
    ];

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.purpleSoft),
              SizedBox(width: 8),
              Text(
                'Tournament Info',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 3.6,
            ),
            itemCount: fields.length,
            itemBuilder: (context, i) => _FieldTile(field: fields[i]),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field});
  final _InfoField field;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(field.icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            field.label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ),
        Text(
          field.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
