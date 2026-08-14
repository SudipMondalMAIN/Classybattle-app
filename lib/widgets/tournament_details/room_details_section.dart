import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tournament_detail_model.dart';
import '../../providers/tournament_providers.dart';
import '../../services/tournament_service.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class RoomDetailsSection extends ConsumerWidget {
  const RoomDetailsSection({
    super.key,
    required this.tournament,
    this.isHost = false,
  });

  final TournamentDetailModel tournament;

  /// True when the logged-in user is the one who created this (Custom)
  /// tournament -- lets them publish room_id/room_password themselves
  /// instead of waiting on an admin.
  final bool isHost;

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _openPublishSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PublishRoomSheet(tournament: tournament),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPublish =
        isHost && !tournament.hasRoomDetails && tournament.status == 'scheduled';

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
        else ...[
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
                    canPublish
                        ? 'You\'re hosting this tournament -- publish the room ID & password when it\'s ready.'
                        : tournament.status == 'scheduled'
                            ? 'Room ID & password will appear here once the organizer publishes them.'
                            : 'Room details aren\'t available for this tournament.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          if (canPublish) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.purpleButton,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () => _openPublishSheet(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Publish Room ID & Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
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

class _PublishRoomSheet extends ConsumerStatefulWidget {
  const _PublishRoomSheet({required this.tournament});
  final TournamentDetailModel tournament;

  @override
  ConsumerState<_PublishRoomSheet> createState() => _PublishRoomSheetState();
}

class _PublishRoomSheetState extends ConsumerState<_PublishRoomSheet> {
  final _roomIdCtrl = TextEditingController();
  final _roomPasswordCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _roomIdCtrl.dispose();
    _roomPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final roomId = _roomIdCtrl.text.trim();
    final roomPassword = _roomPasswordCtrl.text.trim();
    if (roomId.isEmpty || roomPassword.isEmpty) {
      setState(() => _error = 'Room ID and password are both required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await tournamentService.publishRoom(
        tournamentId: widget.tournament.id,
        roomId: roomId,
        roomPassword: roomPassword,
      );
      ref.invalidate(tournamentDetailProvider(widget.tournament.id));
      if (mounted) Navigator.of(context).pop();
    } on SubmitResultException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not publish room details. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publish Room Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'This goes out to every joined player and takes the tournament live.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _sheetField('Room ID', _roomIdCtrl),
              const SizedBox(height: 12),
              _sheetField('Room Password', _roomPasswordCtrl),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.live, fontSize: 12)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleButton,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Publish & Go Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
