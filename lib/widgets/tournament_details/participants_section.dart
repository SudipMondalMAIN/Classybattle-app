import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/participant_public_model.dart';
import '../../theme/app_theme.dart';
import 'report_player_dialog.dart';

/// Full participant roster for a tournament: every participant's
/// avatar/name/in-game nickname+uid, and — once the tournament has
/// results — their rank/win/prize too (see ParticipantPublicModel).
/// Any participant can see every other participant's in-game
/// nickname/uid here, which is intentional (needed to actually find
/// each other in-game), not just their own.
class ParticipantsSection extends StatelessWidget {
  const ParticipantsSection({
    super.key,
    required this.participants,
    required this.totalCount,
    this.currentUserId,
  });

  final List<ParticipantPublicModel> participants;
  final int totalCount;

  /// The signed-in user's id, used to hide the "Report" action on their
  /// own tile. Null (signed out) shows no report action at all.
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.groups_rounded,
              size: 18,
              color: AppColors.purpleSoft,
            ),
            const SizedBox(width: 8),
            const Text(
              'Participants',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$totalCount',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (participants.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No one has joined yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < participants.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == participants.length - 1 ? 0 : 10,
                  ),
                  child: _ParticipantTile(
                    participant: participants[i],
                    canReport: currentUserId != null &&
                        currentUserId != participants[i].userId,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, required this.canReport});
  final ParticipantPublicModel participant;
  final bool canReport;

  @override
  Widget build(BuildContext context) {
    final p = participant;
    final subtitleParts = <String>[
      if (p.ingameNickname != null && p.ingameNickname!.isNotEmpty)
        p.ingameNickname!,
      if (p.ingameUid != null && p.ingameUid!.isNotEmpty) 'UID: ${p.ingameUid}',
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.glassFillStrong,
        borderRadius: BorderRadius.circular(14),
        border: p.isWinner ? Border.all(color: AppColors.gold, width: 1) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.background,
            backgroundImage: p.avatarId != null
                ? AssetImage('assets/avatars/${p.avatarId}.png')
                : null,
            onBackgroundImageError: p.avatarId != null ? (_, __) {} : null,
            child: p.avatarId == null
                ? const Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.textSecondary,
                  )
                : null,
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
                        p.fullName.isNotEmpty ? p.fullName : 'Player',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (p.isWinner) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                    ],
                  ],
                ),
                if (subtitleParts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitleParts.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (p.hasResult) ...[
            const SizedBox(width: 8),
            _ResultBadge(participant: p),
          ],
          if (canReport) ...[
            const SizedBox(width: 4),
            PopupMenuButton<void>(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              padding: EdgeInsets.zero,
              color: AppColors.background,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 16, color: AppColors.live),
                      SizedBox(width: 8),
                      Text('Report player',
                          style: TextStyle(color: AppColors.live)),
                    ],
                  ),
                  onTap: () {
                    Future.microtask(() => showReportPlayerDialog(
                          context,
                          userId: p.userId,
                          playerName: p.fullName.isNotEmpty
                              ? p.fullName
                              : 'this player',
                        ));
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.participant});
  final ParticipantPublicModel participant;

  @override
  Widget build(BuildContext context) {
    final p = participant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (p.rank != null)
          Text(
            'Rank #${p.rank}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (p.winningAmount != null && p.winningAmount! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              formatRupees(p.winningAmount!),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
