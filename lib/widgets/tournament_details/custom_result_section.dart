import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/custom_match_claim_model.dart';
import '../../models/tournament_detail_model.dart';
import '../../providers/tournament_providers.dart';
import '../../providers/wallet_providers.dart';
import '../../services/home_service.dart' show UnauthenticatedException;
import '../../services/tournament_service.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../../providers/home_providers.dart';

/// Self-declared win/loss for 1v1 Custom Tournaments (see
/// CustomMatchClaimService on the backend for the full rules):
///   - Claim LOSS -> no proof, instantly pays the other player.
///   - Claim WIN  -> proof screenshot required, waits for the
///     opponent's confirming claim or an admin review.
///
/// Only rendered when the tournament is eligible (custom, solo,
/// max_players == 2, room already published) -- see the `shouldShow`
/// static helper called from the details screen.
class CustomResultSection extends ConsumerStatefulWidget {
  const CustomResultSection({super.key, required this.tournament});

  final TournamentDetailModel tournament;

  /// Custom tournaments never carry a schedule category (see
  /// TournamentCustomCreate on the backend), so category == null is the
  /// same signal the "Custom" home-screen filter uses.
  static bool shouldShow(TournamentDetailModel t) {
    return t.category == null &&
        t.registrationMode == 'solo' &&
        t.maxPlayers == 2 &&
        t.roomId != null;
  }

  @override
  ConsumerState<CustomResultSection> createState() =>
      _CustomResultSectionState();
}

class _CustomResultSectionState extends ConsumerState<CustomResultSection> {
  File? _proof;
  bool _submitting = false;
  String? _error;

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _proof = File(picked.path));
  }

  Future<void> _submit(String outcome) async {
    if (outcome == 'win' && _proof == null) {
      setState(
        () => _error = 'Attach a screenshot of the winning result first.',
      );
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      String? proofUrl;
      if (outcome == 'win') {
        proofUrl = await tournamentService.uploadResultProof(
          widget.tournament.id,
          _proof!,
        );
      }
      await tournamentService.submitCustomResult(
        widget.tournament.id,
        outcome: outcome,
        proofUrl: proofUrl,
      );
      ref.invalidate(customMatchClaimProvider(widget.tournament.id));
      ref.invalidate(walletProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outcome == 'loss'
                  ? 'Result submitted -- your opponent has been credited.'
                  : 'Result submitted -- waiting for confirmation.',
            ),
          ),
        );
      }
    } on UnauthenticatedException {
      setState(() => _error = 'Please log in again.');
    } on SubmitResultException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimAsync = ref.watch(
      customMatchClaimProvider(widget.tournament.id),
    );

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 18,
                color: AppColors.purpleSoft,
              ),
              SizedBox(width: 8),
              Text(
                'Match Result',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          claimAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.purpleSoft,
                  ),
                ),
              ),
            ),
            error: (_, __) => const Text(
              'Couldn\'t load result status.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            data: (pair) => _buildBody(pair),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CustomMatchClaimPairModel? pair) {
    final mine = pair?.myClaim;

    if (mine != null && mine.isResolved) {
      final won = mine.isWin;
      return _StatusBanner(
        icon: won ? Icons.celebration_outlined : Icons.sports_esports_outlined,
        color: won ? AppColors.success : AppColors.textSecondary,
        text: won
            ? 'You won! Prize credited to your wallet. 🏆'
            : 'Result confirmed. Better luck next time!',
      );
    }

    if (mine != null && mine.isPending) {
      return _StatusBanner(
        icon: Icons.hourglass_top_outlined,
        color: AppColors.gold,
        text: mine.isWin
            ? 'Your win claim is submitted -- waiting for your opponent to confirm or admin review.'
            : 'Result submitted.',
      );
    }

    if (mine != null && mine.isRejected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your previous claim was rejected'
            '${mine.rejectionReason != null ? ': ${mine.rejectionReason}' : '.'}'
            ' You can resubmit below.',
            style: const TextStyle(color: AppColors.live, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildForm(),
        ],
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Match over? Report how it went.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _submitting ? null : _pickProof,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
              color: AppColors.glassFill,
            ),
            child: Row(
              children: [
                Icon(
                  _proof != null
                      ? Icons.check_circle_outline
                      : Icons.upload_outlined,
                  size: 18,
                  color: _proof != null
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _proof != null
                        ? 'Screenshot attached'
                        : 'Attach winning-screenshot (required only if you won)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.live, fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : () => _submit('loss'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppColors.glassBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Lost',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitting ? null : () => _submit('win'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'I Won',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
