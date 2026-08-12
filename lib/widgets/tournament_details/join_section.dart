import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../models/tournament_detail_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/tournament_providers.dart';
import '../../services/home_service.dart' show UnauthenticatedException;
import '../../services/tournament_service.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class JoinSection extends ConsumerStatefulWidget {
  const JoinSection({super.key, required this.tournament});

  final TournamentDetailModel tournament;

  @override
  ConsumerState<JoinSection> createState() => _JoinSectionState();
}

class _JoinSectionState extends ConsumerState<JoinSection> {
  bool _joining = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await tournamentService.joinSolo(widget.tournament.id);
      if (!mounted) return;
      ref.invalidate(myRegistrationProvider(widget.tournament.id));
      ref.invalidate(tournamentDetailProvider(widget.tournament.id));
      ref.invalidate(walletProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You\'re in! Good luck.')),
      );
    } on UnauthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join this tournament.')),
      );
    } on JoinTournamentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final regAsync = ref.watch(myRegistrationProvider(t.id));
    final alreadyJoined = regAsync.valueOrNull?.isActive ?? false;
    final full = t.slotsLeft <= 0;
    final joinable = t.status == 'scheduled' && !alreadyJoined && !full;

    return GlassContainer(
      borderRadius: 20,
      glow: true,
      padding: const EdgeInsets.all(4),
      borderColor: AppColors.glassBorderBright,
      child: GestureDetector(
        onTap: joinable && !_joining ? _join : null,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.purpleDeep.withValues(alpha: 0.55),
              AppColors.purple.withValues(alpha: 0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alreadyJoined
                        ? 'You\'re Registered'
                        : full
                            ? 'Tournament Full'
                            : 'Join Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Entry Fee: ${formatRupees(t.entryFee)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      if (t.isFree) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Free',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: joinable ? Colors.white : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _joining
                  ? const SizedBox(
                      width: 44,
                      height: 18,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${t.currentPlayers} / ${t.maxPlayers}',
                          style: TextStyle(
                            color: joinable ? AppColors.purpleDeep : Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          alreadyJoined ? 'Joined' : full ? 'Full' : 'Joined',
                          style: TextStyle(
                            color: joinable
                                ? AppColors.purpleDeep.withValues(alpha: 0.7)
                                : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
