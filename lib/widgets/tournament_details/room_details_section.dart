import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tournament_detail_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class RoomDetailsSection extends StatelessWidget {
  const RoomDetailsSection({super.key, required this.tournament});

  final TournamentDetailModel tournament;

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.meeting_room_outlined, size: 18, color: AppColors.purpleSoft),
            SizedBox(width: 8),
            Text(
              'Room Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tournament.hasRoomDetails)
          Row(
            children: [
              Expanded(
                child: _RoomField(
                  label: 'ROOM ID',
                  value: tournament.roomId!,
                  onCopy: () => _copy(context, 'Room ID', tournament.roomId!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoomField(
                  label: 'PASSWORD',
                  value: tournament.roomPassword!,
                  onCopy: () => _copy(context, 'Password', tournament.roomPassword!),
                ),
              ),
            ],
          )
        else
          GlassContainer(
            borderRadius: 14,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tournament.status == 'scheduled'
                        ? 'Room ID & password will appear here once the organizer publishes them.'
                        : 'Room details aren\'t available for this tournament.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RoomField extends StatelessWidget {
  const _RoomField({required this.label, required this.value, required this.onCopy});

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: const Icon(Icons.copy_rounded, size: 18, color: AppColors.purpleSoft),
          ),
        ],
      ),
    );
  }
}
