import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/api_exception.dart';
import '../core/game_cache.dart';
import '../models/tournament.dart';
import '../models/participant.dart';
import '../models/game.dart';
import '../services/tournament_service.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import 'tournament_detail_screen.dart';

class _MyEntry {
  final Participant participant;
  final Tournament tournament;
  _MyEntry(this.participant, this.tournament);
}

class MyTournamentsScreen extends StatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  State<MyTournamentsScreen> createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> {
  int _tab = 0; // 0 upcoming(scheduled), 1 live, 2 completed/cancelled

  final _tournamentService = TournamentService();

  bool _loading = true;
  String? _error;
  List<_MyEntry> _entries = [];
  Map<String, Game> _games = {};

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
      final registrations = await _tournamentService.myRegistrations(pageSize: 50);
      final games = await GameCache.instance.byId();

      // De-dupe tournament fetches in case a user re-joined the same
      // tournament after cancelling (unlikely, but avoids extra calls).
      final tournamentIds = registrations.map((p) => p.tournamentId).toSet().toList();
      final tournaments = await Future.wait(tournamentIds.map((id) => _tournamentService.getById(id)));
      final tournamentsById = {for (final t in tournaments) t.id: t};

      final entries = registrations
          .where((p) => tournamentsById.containsKey(p.tournamentId))
          .map((p) => _MyEntry(p, tournamentsById[p.tournamentId]!))
          .toList();

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _games = games;
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

  String _gameName(String gameId) => _games[gameId]?.name ?? 'Unknown';

  List<_MyEntry> get _filtered {
    return _entries.where((e) {
      final status = e.tournament.status;
      switch (_tab) {
        case 1:
          return status == 'live';
        case 2:
          return status == 'completed' || status == 'cancelled';
        default:
          return status == 'scheduled';
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 14),
                  const Text('My Tournaments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  children: List.generate(3, (i) {
                    final labels = ['Upcoming', 'Live', 'Completed'];
                    final selected = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: selected ? AppColors.primaryGradient : null,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          alignment: Alignment.center,
                          child: Text(labels[i],
                              style: TextStyle(
                                  color: selected ? Colors.white : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SkeletonListPage(count: 5, leadingCircle: false);
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
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
            ],
          ),
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text('No ${_tab == 0 ? 'upcoming' : _tab == 1 ? 'live' : 'completed'} tournaments',
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: list.length,
        itemBuilder: (context, i) => _RegisteredCard(
          entry: list[i],
          gameName: _gameName(list[i].tournament.gameId),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: list[i].tournament.id)),
          ).then((_) => _load()),
        ),
      ),
    );
  }
}

class _RegisteredCard extends StatelessWidget {
  final _MyEntry entry;
  final String gameName;
  final VoidCallback onTap;
  const _RegisteredCard({required this.entry, required this.gameName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = entry.tournament;
    final p = entry.participant;
    final statusColor = switch (p.status) {
      'registered' || 'checked_in' => AppColors.success,
      'cancelled' => AppColors.textMuted,
      'disqualified' => AppColors.danger,
      _ => AppColors.textSecondary,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            GameIcon(game: gameName, imageUrl: t.coverUrl ?? t.bannerUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.title,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      StatusPill(text: p.status.toUpperCase(), color: statusColor),
                    ],
                  ),
                  Text(gameName, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            Text(TournamentStatusStyle.of(t.status).label,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Slots', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            Text('${t.currentPlayers}/${t.maxPlayers}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Entry Fee', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            Text('₹${formatMoney(t.entryFee)}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
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
}
