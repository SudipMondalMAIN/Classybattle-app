import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../models/tournament_detail_model.dart';
import '../../providers/game_profile_providers.dart';
import '../../providers/home_providers.dart';
import '../../providers/tournament_providers.dart';
import '../../services/home_service.dart' show UnauthenticatedException;
import '../../services/tournament_service.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../game_profile/add_game_profile_sheet.dart';

class JoinSection extends ConsumerStatefulWidget {
  const JoinSection({super.key, required this.tournament});

  final TournamentDetailModel tournament;

  @override
  ConsumerState<JoinSection> createState() => _JoinSectionState();
}

class _JoinSectionState extends ConsumerState<JoinSection> {
  bool _joining = false;

  Future<void> _join() async {
    // Before joining, make sure the user has saved their in-game
    // Nickname/UID for this tournament's game. Without it the
    // organizer has no way to find them in the match -- so we stop
    // here and open the same Add Game Profile sheet used in the Game
    // Profiles screen, and only continue to the actual join once it's
    // saved.
    final games = await ref.read(gamesByIdProvider.future);
    final game = games[widget.tournament.gameId];
    if (game != null && game.profileSchema.isNotEmpty) {
      final hasProfile = await ref.read(
        hasGameProfileProvider(widget.tournament.gameId).future,
      );
      if (!hasProfile) {
        if (!mounted) return;
        final saved = await AddGameProfileSheet.show(context, game);
        if (saved != true) return; // user backed out of the sheet
        ref.invalidate(myGameProfilesProvider);
        ref.invalidate(hasGameProfileProvider(widget.tournament.gameId));
      }
    }

    if (!mounted) return;
    setState(() => _joining = true);
    try {
      await tournamentService.joinSolo(widget.tournament.id);
      if (!mounted) return;
      ref.invalidate(myRegistrationProvider(widget.tournament.id));
      ref.invalidate(tournamentDetailProvider(widget.tournament.id));
      ref.invalidate(walletProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You joined the tournament! Wait for the custom room ID & password.',
          ),
        ),
      );
    } on UnauthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join this tournament.')),
      );
    } on JoinTournamentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: entry fee on the left, entries filled on the right --
            // kept apart so "how much it costs" and "how many have
            // joined" don't get visually mixed into one number.
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Entry Fee: ${formatRupees(t.entryFee)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (t.isFree) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
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
                ),
                Icon(
                  Icons.people_alt_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${t.currentPlayers}/${t.maxPlayers} joined',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Row 2: the actual call to action -- one clear full-width
            // button whose label and enabled state say exactly what
            // will happen and what state the user is in.
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: joinable && !_joining ? _join : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: joinable
                        ? Colors.white
                        : alreadyJoined
                        ? AppColors.success.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: alreadyJoined
                        ? Border.all(
                            color: AppColors.success.withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: _joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.purple,
                          ),
                        )
                      : Text(
                          alreadyJoined
                              ? 'You joined the tournament'
                              : full
                              ? 'Tournament Full'
                              : 'JOIN NOW',
                          style: TextStyle(
                            color: joinable
                                ? AppColors.purpleDeep
                                : alreadyJoined
                                ? AppColors.success
                                : Colors.white54,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
            if (alreadyJoined) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Wait for the custom room ID & password to be published.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
