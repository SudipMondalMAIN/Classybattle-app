import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tournament_detail_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/tournament_providers.dart';
import '../../services/home_service.dart' show UnauthenticatedException;
import '../../services/tournament_service.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

/// Grace period (mirrors the backend's
/// ParticipantService.CUSTOM_HOST_CANCEL_GRACE_MINUTES) after which a
/// Custom Tournament host may cancel their own join or delete the
/// tournament outright, but only while nobody else has joined yet.
const int _kCustomHostCancelGraceMinutes = 10;

/// Shown only to the host of their own user-hosted Custom Tournament,
/// while it's still SCHEDULED. Offers "Cancel Join" (leave, refunded)
/// and "Delete Tournament" (remove entirely, refunded) -- both enabled
/// only once the grace period has passed with still no opponent
/// having joined; the backend enforces the same rule regardless of
/// what this widget shows.
class HostCancelSection extends ConsumerStatefulWidget {
  const HostCancelSection({super.key, required this.tournament});

  final TournamentDetailModel tournament;

  static bool shouldShow(TournamentDetailModel t, String? currentUserId) {
    return t.isCustomHosted &&
        t.status == 'scheduled' &&
        currentUserId != null &&
        t.createdBy == currentUserId;
  }

  @override
  ConsumerState<HostCancelSection> createState() => _HostCancelSectionState();
}

class _HostCancelSectionState extends ConsumerState<HostCancelSection> {
  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Re-render every 30s so the countdown / unlocked state stays live
    // without the user needing to pull-to-refresh.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration? get _remaining {
    final createdAt = widget.tournament.createdAt;
    if (createdAt == null) return null;
    final unlockAt =
        createdAt.add(const Duration(minutes: _kCustomHostCancelGraceMinutes));
    final diff = unlockAt.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get _opponentJoined => widget.tournament.currentPlayers > 1;

  bool get _unlocked =>
      !_opponentJoined && (_remaining == null || _remaining == Duration.zero);

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Never mind'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel,
                style: const TextStyle(color: AppColors.live)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(tournamentDetailProvider(widget.tournament.id));
      ref.invalidate(myRegistrationProvider(widget.tournament.id));
      ref.invalidate(allTournamentsProvider);
      ref.invalidate(customTournamentsProvider);
      ref.invalidate(walletProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    } on UnauthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in and try again.')),
      );
    } on CancelTournamentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelJoin() => _confirmAndRun(
        title: 'Cancel your join?',
        message:
            'Your entry fee will be refunded to your wallet, and the '
            'tournament will stay open for others to join instead.',
        confirmLabel: 'Cancel join',
        action: () => tournamentService.cancelCustomJoin(widget.tournament.id),
        successMessage: 'Your join was cancelled and refunded.',
      );

  Future<void> _delete() => _confirmAndRun(
        title: 'Delete this tournament?',
        message:
            'This removes the tournament entirely and refunds your entry '
            'fee. This can\'t be undone.',
        confirmLabel: 'Delete',
        action: () => tournamentService.deleteCustomTournament(widget.tournament.id),
        successMessage: 'Tournament deleted and your entry fee refunded.',
      );

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final unlocked = _unlocked;

    String helperText;
    if (_opponentJoined) {
      helperText =
          'An opponent has already joined -- this tournament can no longer '
          'be cancelled or deleted.';
    } else if (unlocked) {
      helperText =
          'Still no opponent has joined. You can cancel your join or '
          'delete this tournament.';
    } else {
      final mins = remaining!.inMinutes;
      final secs = remaining.inSeconds % 60;
      helperText =
          'If nobody joins, you\'ll be able to cancel or delete this in '
          '${mins}m ${secs.toString().padLeft(2, '0')}s.';
    }

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.manage_accounts_rounded,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Hosting this tournament',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: unlocked && !_busy ? _cancelJoin : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.glassBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel Join'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: unlocked && !_busy ? _delete : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.live,
                    side: BorderSide(color: AppColors.live.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.live),
                        )
                      : const Text('Delete Tournament'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
