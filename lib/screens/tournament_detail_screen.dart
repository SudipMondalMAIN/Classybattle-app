import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../core/api_exception.dart';
import '../core/game_cache.dart';
import '../models/tournament.dart';
import '../models/participant.dart';
import '../models/game.dart';
import '../models/wallet.dart';
import '../services/tournament_service.dart';
import '../services/wallet_service.dart';
import '../widgets/common.dart';
import '../widgets/app_header.dart';
import '../widgets/skeleton.dart';
import 'auth/auth_widgets.dart';
import 'tournaments/join_tournament_flow.dart';
import 'tournaments_screen.dart' show gameTint, GlassCard;

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> {
  final _tournamentService = TournamentService();
  final _walletService = WalletService();

  bool _loading = true;
  String? _error;
  Tournament? _tournament;
  Game? _game;
  Participant? _myRegistration;
  bool _actionInProgress = false;
  double _walletBalance = 0;

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
      final results = await Future.wait([
        _tournamentService.getById(widget.tournamentId),
        GameCache.instance.byId(),
        _tournamentService.getMyRegistration(widget.tournamentId),
        _walletService.getWallet(),
      ]);
      if (!mounted) return;
      final tournament = results[0] as Tournament;
      final games = results[1] as Map<String, Game>;
      setState(() {
        _tournament = tournament;
        _game = games[tournament.gameId];
        _myRegistration = results[2] as Participant?;
        _walletBalance = (results[3] as Wallet).availableBalance;
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

  void _copy(String label, String value) {
    showAuthSnack(context, '$label copied', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgBottom,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              Row(
                children: [
                  const SkeletonCircle(size: 30),
                  const Spacer(),
                  const SkeletonCircle(size: 30),
                ],
              ),
              const SizedBox(height: 18),
              SkeletonBox(height: 170, radius: AppRadius.lg),
              const SizedBox(height: 18),
              const SkeletonBox(width: 220, height: 20),
              const SizedBox(height: 10),
              const SkeletonBox(width: 140, height: 13),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 70, radius: AppRadius.md)),
                  const SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 70, radius: AppRadius.md)),
                  const SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 70, radius: AppRadius.md)),
                ],
              ),
              const SizedBox(height: 22),
              const SkeletonBox(width: 140, height: 16),
              const SizedBox(height: 12),
              SkeletonBox(height: 100, radius: AppRadius.lg),
            ],
          ),
        ),
      );
    }
    if (_error != null || _tournament == null) {
      return Scaffold(
        backgroundColor: AppColors.bgBottom,
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
                GradientButton(label: 'RETRY', onTap: _load),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final t = _tournament!;
    final gameName = _game?.name ?? 'Unknown';
    final statusStyle = TournamentStatusStyle.of(t.status);
    final registered = _myRegistration != null &&
        _myRegistration!.status != 'cancelled' &&
        _myRegistration!.status != 'disqualified';

    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: AppHeader(
                showBack: true,
                title: 'Tournament Details',
                walletBalance: _walletBalance,
                showOnlineDot: true,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColors.purple,
                backgroundColor: AppColors.surface,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  children: [
                    _buildHero(t, gameName, statusStyle),
                    const SizedBox(height: 16),
                    _buildJoinBar(t, registered),
                    const SizedBox(height: 20),
                    _buildTournamentInfo(t, gameName),
                    const SizedBox(height: 20),
                    if (t.roomId != null || t.roomPassword != null) ...[
                      _buildRoomDetails(t),
                      const SizedBox(height: 20),
                    ],
                    _buildPrizePool(t),
                    const SizedBox(height: 20),
                    _buildRules(t),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: _buildActionButton(t, registered),
      ),
    );
  }

  // ---- Hero banner -------------------------------------------------

  Widget _buildHero(Tournament t, String gameName, TournamentStatusStyle statusStyle) {
    final tint = gameTint(gameName);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tint.withValues(alpha: 0.55), AppColors.bgTop, AppColors.bgTop],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.7, 1],
          ),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 20,
              child: Icon(Icons.military_tech_rounded, color: Colors.white.withValues(alpha: 0.14), size: 190),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: AppColors.danger, size: 8),
                    const SizedBox(width: 5),
                    Text(statusStyle.label,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 130,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRIZE POOL', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    const SizedBox(height: 3),
                    Text('₹${formatMoney(t.prizePool)}',
                        style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('ENTRIES', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    const SizedBox(height: 3),
                    Text('${t.currentPlayers} / ${t.maxPlayers}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('TIME LEFT', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    const SizedBox(height: 3),
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('2h 15m', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 150,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gameName.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  const SizedBox(height: 4),
                  Text(t.title,
                      style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    t.description?.trim().isNotEmpty == true ? t.description! : 'Clash. Compete. Conquer.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _tagChip(Icons.groups_rounded, t.registrationMode == 'solo' ? 'Solo' : 'Squad'),
                      _tagChip(Icons.center_focus_strong_rounded, 'TPP'),
                      _tagChip(Icons.map_rounded, 'Erangel'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ---- Join bar ------------------------------------------------------

  Widget _buildJoinBar(Tournament t, bool registered) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(registered ? 'You\'re Registered' : 'Join Now',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Entry Fee: ₹${formatMoney(t.entryFee)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    if (t.entryFee == 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration:
                            BoxDecoration(color: AppColors.success.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: const Text('Free',
                            style: TextStyle(color: AppColors.success, fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text('${t.currentPlayers} / ${t.maxPlayers}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const Text('Joined', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Tournament info -------------------------------------------------

  Widget _buildTournamentInfo(Tournament t, String gameName) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.info_outline_rounded, 'Tournament Info'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _infoRow(Icons.sports_esports_rounded, 'Game', gameName),
                    _infoRow(Icons.groups_rounded, 'Game Mode', t.registrationMode == 'solo' ? 'Solo' : 'Squad'),
                    _infoRow(Icons.center_focus_strong_rounded, 'Perspective', 'TPP'),
                    _infoRow(Icons.map_outlined, 'Map', 'Erangel'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _infoRow(Icons.auto_awesome_rounded, 'Type', t.isFeatured ? 'Featured' : 'Classic'),
                    _infoRow(Icons.people_alt_rounded, 'Max Players', '${t.maxPlayers}'),
                    _infoRow(Icons.public_rounded, 'Region', 'India'),
                    _infoRow(Icons.settings_rounded, 'Version', 'Latest'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ),
            Text(value,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  // ---- Room details -------------------------------------------------

  Widget _buildRoomDetails(Tournament t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle(Icons.meeting_room_outlined, 'Room Details'),
        const SizedBox(height: 12),
        Row(
          children: [
            if (t.roomId != null)
              Expanded(child: _roomBox('ROOM ID', t.roomId!)),
            if (t.roomId != null && t.roomPassword != null) const SizedBox(width: 12),
            if (t.roomPassword != null)
              Expanded(child: _roomBox('PASSWORD', t.roomPassword!)),
          ],
        ),
      ],
    );
  }

  Widget _roomBox(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _copy(label, value),
              child: const Icon(Icons.copy_rounded, color: AppColors.purple, size: 18),
            ),
          ],
        ),
      );

  // ---- Prize pool -------------------------------------------------

  Widget _buildPrizePool(Tournament t) {
    final first = t.prizePool * 0.5;
    final second = t.prizePool * 0.3;
    final third = t.prizePool * 0.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _cardTitle(Icons.emoji_events_outlined, 'Prize Pool'),
            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('View Prize Distribution',
                      style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded, color: AppColors.purple, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _prizeBox('1st Prize', first, Icons.emoji_events_rounded, AppColors.gold)),
            const SizedBox(width: 10),
            Expanded(child: _prizeBox('2nd Prize', second, Icons.emoji_events_rounded, const Color(0xFFBFC7D5))),
            const SizedBox(width: 10),
            Expanded(child: _prizeBox('3rd Prize', third, Icons.emoji_events_rounded, const Color(0xFFCD7F32))),
          ],
        ),
      ],
    );
  }

  Widget _prizeBox(String label, double amount, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
            const SizedBox(height: 4),
            Text('₹${formatMoney(amount)}',
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  // ---- Rules -------------------------------------------------

  Widget _buildRules(Tournament t) {
    final defaultRules = [
      'Players must be in the lobby 10 minutes before the match starts.',
      'Use of hacks, cheats or any 3rd party app is strictly prohibited.',
      'Abusive behaviour or teaming with other teams will lead to disqualification.',
      "Organizer's decision will be final and binding.",
    ];
    final rules = t.rules?.trim().isNotEmpty == true
        ? t.rules!.split('\n').where((r) => r.trim().isNotEmpty).toList()
        : defaultRules;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.receipt_long_rounded, 'Tournament Rules'),
          const SizedBox(height: 12),
          ...rules.take(4).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, color: AppColors.purple, size: 5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(r.trim(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
                    ),
                  ],
                ),
              )),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('View All Rules',
                      style: TextStyle(color: AppColors.purple, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded, color: AppColors.purple, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: AppColors.purple, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      );

  // ---- Action button -------------------------------------------------

  Widget _buildActionButton(Tournament t, bool registered) {
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
}
