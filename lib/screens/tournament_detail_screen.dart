import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/api_exception.dart';
import '../core/game_cache.dart';
import '../models/tournament.dart';
import '../models/participant.dart';
import '../models/game.dart';
import '../services/tournament_service.dart';
import '../widgets/common.dart';
import 'auth/auth_widgets.dart';
import 'tournaments/join_tournament_flow.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  int _tab = 0;
  final _tabs = ['Details', 'Rules', 'Prize', 'Participants'];

  final _tournamentService = TournamentService();

  bool _loading = true;
  String? _error;
  Tournament? _tournament;
  Game? _game;
  Participant? _myRegistration;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tournament = await _tournamentService.getById(widget.tournamentId);
      final games = await GameCache.instance.byId();
      final myRegistration = await _tournamentService.getMyRegistration(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _tournament = tournament;
        _game = games[tournament.gameId];
        _myRegistration = myRegistration;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    final t = _tournament;
    if (t == null) return;
    setState(() => _actionInProgress = true);
    final participant = await runJoinTournamentFlow(context, tournamentId: t.id, gameId: t.gameId);
    if (!mounted) return;
    setState(() => _actionInProgress = false);
    if (participant != null) _load();
  }

  Future<void> _cancel() async {
    setState(() => _actionInProgress = true);
    try {
      await _tournamentService.cancelRegistration(widget.tournamentId);
      if (!mounted) return;
      showAuthSnack(context, 'Registration has been cancelled', isError: false);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionInProgress = false);
      showAuthSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    if (_error != null || _tournament == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(_error ?? 'Tournament not found',
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final t = _tournament!;
    final gameName = _game?.name ?? 'Unknown';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHero(t, gameName),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColors.purple,
                backgroundColor: AppColors.surface,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              Text('₹${formatMoney(t.prizePool)}',
                                  style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Entry Fee', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              Text('₹${formatMoney(t.entryFee)}',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          _infoStat(Icons.groups_rounded, t.registrationMode == 'solo' ? 'Solo' : 'Team'),
                          _divider(),
                          _infoStat(Icons.person_rounded, '${t.teamSize} Player${t.teamSize > 1 ? 's' : ''}'),
                          _divider(),
                          _infoStat(Icons.emoji_events_rounded, t.isFeatured ? 'Featured' : 'Standard'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _detailRow('Status', TournamentStatusStyle.of(t.status).label),
                    _detailRow('Slots', '${t.currentPlayers}/${t.maxPlayers}'),
                    if (t.organizer != null) _detailRow('Organizer', t.organizer!),
                    if (_myRegistration != null) _detailRow('Your Status', _myRegistration!.status),
                    if (t.roomId != null) _detailRow('Room ID', t.roomId!),
                    if (t.roomPassword != null) _detailRow('Room Password', t.roomPassword!),
                    const SizedBox(height: 18),
                    _buildTabs(),
                    const SizedBox(height: 16),
                    _buildTabContent(t),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: _buildActionButton(t),
      ),
    );
  }

  Widget _buildActionButton(Tournament t) {
    final registered = _myRegistration != null &&
        _myRegistration!.status != 'cancelled' &&
        _myRegistration!.status != 'disqualified';

    if (_actionInProgress) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    if (registered) {
      final canCancel = t.status == 'scheduled';
      return GradientButton(
        label: canCancel ? 'CANCEL REGISTRATION' : 'REGISTERED',
        height: 52,
        width: double.infinity,
        fontSize: 15,
        onTap: canCancel ? _cancel : null,
      );
    }

    if (t.status != 'scheduled') {
      return GradientButton(label: 'JOINING CLOSED', height: 52, width: double.infinity, fontSize: 15, onTap: null);
    }
    if (t.isFull) {
      return GradientButton(label: 'TOURNAMENT FULL', height: 52, width: double.infinity, fontSize: 15, onTap: null);
    }
    return GradientButton(label: 'JOIN TOURNAMENT', height: 52, width: double.infinity, fontSize: 15, onTap: _join);
  }

  Widget _infoStat(IconData icon, String label) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppColors.purple, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 34, color: AppColors.cardBorder);

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _buildHero(Tournament t, String gameName) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1760), Color(0xFF120B26)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [AppColors.purple.withValues(alpha: 0.35), Colors.transparent],
                  radius: 0.9,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleIcon(Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gameName,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text(t.title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (i) {
        final selected = i == _tab;
        return Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Column(
              children: [
                Text(_tabs[i],
                    style: TextStyle(
                        color: selected ? AppColors.purple : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (selected)
                  Container(width: 20, height: 2, decoration: BoxDecoration(gradient: AppColors.primaryGradient)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabContent(Tournament t) {
    switch (_tab) {
      case 1:
        return Text(
          t.rules?.trim().isNotEmpty == true
              ? t.rules!
              : 'No specific rules have been set for this tournament. Please follow general fair-play rules.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.8),
        );
      case 2:
        return Text('Total prize pool: ₹${formatMoney(t.prizePool)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6));
      case 3:
        return Text('${t.currentPlayers} player registered out of ${t.maxPlayers} slots.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6));
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About Tournament',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              t.description?.trim().isNotEmpty == true
                  ? t.description!
                  : 'Join the tournament and compete with the best players. Show your skills and win big prizes!',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.7),
            ),
          ],
        );
    }
  }
}
