import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../core/api_exception.dart';
import '../core/game_cache.dart';
import '../models/tournament.dart';
import '../models/game.dart';
import '../models/wallet.dart';
import '../services/tournament_service.dart';
import '../services/wallet_service.dart';
import 'tournament_detail_screen.dart';
import 'tournaments/join_tournament_flow.dart';
import '../widgets/common.dart';
import '../widgets/app_header.dart';
import '../widgets/skeleton.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen> {
  final _tournamentService = TournamentService();
  final _walletService = WalletService();

  int _tabIndex = 0; // All, Live, Upcoming, Completed, My Tournaments
  static const _tabLabels = ['All', 'Live', 'Upcoming', 'Completed', 'My Tournaments'];

  bool _loading = true;
  String? _error;
  List<Tournament> _live = [];
  List<Tournament> _upcoming = [];
  double _walletBalance = 0;
  Map<String, Game> _gamesById = {};

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        GameCache.instance.byId(),
        _tournamentService.list(status: 'ongoing', pageSize: 20),
        _tournamentService.list(status: 'upcoming', pageSize: 20),
        _walletService.getWallet(),
      ]);
      if (!mounted) return;
      setState(() {
        _gamesById = results[0] as Map<String, Game>;
        _live = results[1] as List<Tournament>;
        _upcoming = results[2] as List<Tournament>;
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

  String _gameName(String gameId) => _gamesById[gameId]?.name ?? 'Unknown';

  Widget _skeleton() {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        children: [
          Row(
            children: [
              const SkeletonCircle(size: 32),
              const Spacer(),
              const SkeletonBox(width: 70, height: 30, radius: AppRadius.pill),
            ],
          ),
          const SizedBox(height: 22),
          const SkeletonBox(width: 170, height: 24),
          const SizedBox(height: 8),
          const SkeletonBox(width: 140, height: 13),
          const SizedBox(height: 16),
          SkeletonBox(height: 44, radius: AppRadius.pill),
          const SizedBox(height: 14),
          SkeletonBox(height: 38, radius: AppRadius.pill),
          const SizedBox(height: 24),
          const SkeletonBox(width: 140, height: 16),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SkeletonBox(width: 230, height: 300, radius: AppRadius.lg),
            ),
          ),
          const SizedBox(height: 22),
          const SkeletonBox(width: 170, height: 16),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonBox(height: 92, radius: AppRadius.lg),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _join(Tournament t) async {
    final participant = await runJoinTournamentFlow(context, tournamentId: t.id, gameId: t.gameId);
    if (participant != null) _load();
  }

  void _openDetail(Tournament t) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _skeleton();
    }
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.purple,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          children: [
            AppHeader(walletBalance: _walletBalance),
            const SizedBox(height: 22),
            const Text('Tournaments',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Compete. Conquer. Win.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _buildSearchRow(),
            const SizedBox(height: 14),
            _buildTabs(),
            const SizedBox(height: 24),
            if (_error != null)
              _buildErrorState()
            else ...[
              _sectionHeader('Live Tournaments'),
              const SizedBox(height: 12),
              if (_live.isEmpty)
                const _EmptyHint(text: 'No live tournaments right now')
              else
                SizedBox(
                  height: 300,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _live.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _LiveTournamentCard(
                      t: _live[i],
                      gameName: _gameName(_live[i].gameId),
                      onTap: () => _openDetail(_live[i]),
                      onJoin: () => _join(_live[i]),
                    ),
                  ),
                ),
              const SizedBox(height: 26),
              _sectionHeader('Upcoming Tournaments'),
              const SizedBox(height: 12),
              if (_upcoming.isEmpty)
                const _EmptyHint(text: 'No upcoming tournaments right now')
              else
                ..._upcoming.map((t) => _UpcomingTournamentTile(
                      t: t,
                      gameName: _gameName(t.gameId),
                      onTap: () => _openDetail(t),
                      onJoin: () => _join(t),
                    )),
              const SizedBox(height: 26),
              _sectionHeader('Your Tournaments'),
              const SizedBox(height: 12),
              _buildYourTournamentsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View All',
                    style: TextStyle(fontSize: 13, color: AppColors.purple, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, color: AppColors.purple, size: 18),
              ],
            ),
          ),
        ],
      );

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search tournaments...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 18),
              SizedBox(width: 6),
              Text('Filters', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selected = i == _tabIndex;
          final showLiveBadge = i == 1 && _live.isNotEmpty;
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.purple : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_tabLabels[i],
                      style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                  if (showLiveBadge) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text('${_live.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYourTournamentsCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Row(
        children: [
          _yourStat(icon: Icons.emoji_events_rounded, iconBg: AppColors.purple, value: '12', label: 'Joined'),
          _statDivider(),
          _yourStat(icon: Icons.star_rounded, iconBg: AppColors.gold, value: '4', label: 'Won'),
          _statDivider(),
          _yourStat(
              icon: Icons.account_balance_wallet_rounded,
              iconBg: AppColors.success,
              value: '₹7,500',
              label: 'Total Winnings'),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: AppColors.cardBorder);

  Widget _yourStat({required IconData icon, required Color iconBg, required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: iconBg, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          GradientButton(label: 'RETRY', onTap: _load, height: 40),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
    );
  }
}

/// Reusable flat card used for "Your Tournaments" etc.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

Color gameTint(String game) {
  switch (game.toUpperCase()) {
    case 'BGMI':
      return const Color(0xFF4C6EF5);
    case 'FREE FIRE':
      return const Color(0xFFE8590C);
    case 'CLASH SQUAD':
      return const Color(0xFF9C36B5);
    case 'VALORANT':
      return const Color(0xFFE03131);
    case 'CALL OF DUTY':
    case 'CODM':
      return const Color(0xFF2F9E44);
    case 'NEW STATE MOBILE':
      return const Color(0xFF1098AD);
    default:
      return AppColors.purple;
  }
}

IconData gameIconFor(String game) {
  switch (game.toUpperCase()) {
    case 'BGMI':
    case 'NEW STATE MOBILE':
      return Icons.military_tech_rounded;
    case 'FREE FIRE':
      return Icons.local_fire_department_rounded;
    case 'CLASH SQUAD':
      return Icons.groups_rounded;
    case 'VALORANT':
      return Icons.grid_view_rounded;
    case 'CALL OF DUTY':
    case 'CODM':
      return Icons.gps_fixed_rounded;
    default:
      return Icons.sports_esports_rounded;
  }
}

class GameBanner extends StatelessWidget {
  final String gameName;
  final double height;
  final BorderRadius borderRadius;
  final String? imageUrl;
  const GameBanner({super.key, required this.gameName, required this.height, required this.borderRadius, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final tint = gameTint(gameName);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: [tint.withValues(alpha: 0.55), AppColors.bgTop],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(gameIconFor(gameName), color: Colors.white.withValues(alpha: 0.85), size: height * 0.4),
          ),
          NetworkCover(imageUrl: imageUrl, borderRadius: borderRadius),
        ],
      ),
    );
  }
}

class _LiveTournamentCard extends StatelessWidget {
  final Tournament t;
  final String gameName;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  const _LiveTournamentCard({required this.t, required this.gameName, this.onTap, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final canJoin = t.status == 'scheduled' || t.status == 'live';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 235,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GameBanner(
                  gameName: gameName,
                  height: 120,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  imageUrl: t.coverUrl ?? t.bannerUrl,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, color: AppColors.danger, size: 7),
                        SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('${t.currentPlayers}/${t.maxPlayers}',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gameName.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.purple, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  const SizedBox(height: 3),
                  Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 13),
                                const SizedBox(width: 3),
                                Text('₹${formatMoney(t.prizePool)}',
                                    style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time Left', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 3),
                            Row(
                              children: const [
                                Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 13),
                                SizedBox(width: 3),
                                Text('2h 15m',
                                    style: TextStyle(
                                        color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GradientButton(label: 'Join', onTap: canJoin ? onJoin : null, height: 40, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTournamentTile extends StatelessWidget {
  final Tournament t;
  final String gameName;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  const _UpcomingTournamentTile({required this.t, required this.gameName, this.onTap, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final date = t.publishedAt;
    final dateLabel = date != null ? '${date.day} ${_month(date.month)}, ${date.year}' : 'TBA';
    final timeLabel = date != null
        ? '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}'
        : '--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: GameBanner(
                gameName: gameName,
                height: 68,
                borderRadius: BorderRadius.circular(AppRadius.md),
                imageUrl: t.coverUrl ?? t.bannerUrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gameName.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(dateLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                const SizedBox(height: 2),
                Text('₹${formatMoney(t.prizePool)}',
                    style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                GradientButton(
                    label: 'Join',
                    height: 32,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    onTap: onJoin),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}
