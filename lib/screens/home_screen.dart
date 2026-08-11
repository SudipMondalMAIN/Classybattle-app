import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../core/api_exception.dart';
import '../core/game_cache.dart';
import '../models/tournament.dart';
import '../models/game.dart';
import '../models/wallet.dart';
import '../providers/auth_provider.dart';
import '../services/tournament_service.dart';
import '../services/wallet_service.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/skeleton.dart';
import 'add_money_screen.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tournament_detail_screen.dart';
import 'tournaments_screen.dart';
import 'game_profiles_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  final _tournamentService = TournamentService();
  final _walletService = WalletService();

  bool _loading = true;
  String? _error;
  List<Tournament> _live = [];
  List<Tournament> _featured = [];
  List<Tournament> _upcoming = [];
  Map<String, Game> _games = {};
  double? _walletBalance;

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
        _tournamentService.list(status: 'ongoing', pageSize: 5),
        _tournamentService.list(isFeatured: true, pageSize: 5),
        _tournamentService.list(status: 'upcoming', pageSize: 5),
        GameCache.instance.byId(),
        _walletService.getWallet(),
      ]);
      if (!mounted) return;
      setState(() {
        _live = results[0] as List<Tournament>;
        _featured = results[1] as List<Tournament>;
        _upcoming = results[2] as List<Tournament>;
        _games = results[3] as Map<String, Game>;
        _walletBalance = (results[4] as Wallet).availableBalance;
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    if (_loading) {
      return _skeleton();
    }
    if (_error != null) {
      return _buildErrorState();
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.purple,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          children: [
            _buildTopBar(user?.fullName),
            const SizedBox(height: 16),
            _buildBanner(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Live Tournaments',
              action: 'View All',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen())),
            ),
            const SizedBox(height: 12),
            if (_live.isEmpty)
              const _EmptyRow(text: 'No live tournaments right now')
            else
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _live.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _LiveTournamentCard(t: _live[i], gameName: _gameName(_live[i].gameId)),
                ),
              ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Upcoming Tournaments',
              action: 'View All',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen())),
            ),
            const SizedBox(height: 12),
            if (_upcoming.isEmpty)
              const _EmptyRow(text: 'No upcoming tournaments right now')
            else
              ..._upcoming.map((t) => _UpcomingTournamentCard(t: t, gameName: _gameName(t.gameId))),
            const SizedBox(height: 22),
            const _HowItWorks(),
          ],
        ),
      ),
    );
  }

  Widget _skeleton() {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        children: [
          Row(
            children: [
              const SkeletonBox(width: 130, height: 22),
              const Spacer(),
              const SkeletonBox(width: 70, height: 30, radius: AppRadius.pill),
              const SizedBox(width: 10),
              const SkeletonCircle(size: 32),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonBox(height: 150, radius: AppRadius.lg),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 3 ? 0 : 10),
                  child: const SkeletonBox(height: 64, radius: AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SkeletonBox(width: 150, height: 16),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SkeletonBox(width: 210, height: 190, radius: AppRadius.lg),
            ),
          ),
          const SizedBox(height: 22),
          const SkeletonBox(width: 190, height: 16),
          const SizedBox(height: 12),
          ...List.generate(
            2,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonBox(height: 92, radius: AppRadius.lg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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

  Widget _buildTopBar(String? fullName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          child: ShaderMask(
            shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 6),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            children: [
              TextSpan(text: 'Classy', style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(text: 'Battle', style: TextStyle(color: AppColors.purple)),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMoneyScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.gold, size: 14),
                const SizedBox(width: 5),
                Text('₹${formatMoney(_walletBalance ?? 0)}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.add_circle_rounded, color: AppColors.purple, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 18),
              ),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgBottom, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              (fullName == null || fullName.trim().isEmpty) ? '?' : fullName.trim()[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  List<Tournament> get _bannerItems => _featured.isNotEmpty ? _featured : _live;

  Widget _buildBanner() {
    final items = _bannerItems;
    final count = items.isEmpty ? 1 : items.length;
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: count,
            itemBuilder: (context, i) {
              final t = items.isEmpty ? null : items[i];
              final gameName = t == null ? 'BGMI' : _gameName(t.gameId);
              return _BannerCard(
                tournament: t,
                gameName: gameName,
                onJoin: () {
                  if (t == null) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id)));
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.purple : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final items = [
      (Icons.sports_esports_rounded, 'All Games', AppColors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameProfilesScreen()))),
      (Icons.emoji_events_rounded, 'Tournaments', AppColors.gold, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen()))),
      (Icons.card_giftcard_rounded, 'Rewards', AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
      (Icons.shield_rounded, 'Leaderboard', AppColors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
    ];
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: AppRadius.xl,
      blur: 16,
      opacity: 0.06,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((it) {
          final (icon, label, color, onTap) = it;
          return GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Tournament? tournament;
  final String gameName;
  final VoidCallback onJoin;
  const _BannerCard({required this.tournament, required this.gameName, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A1A6B), Color(0xFF15101F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            top: 10,
            child: Icon(Icons.military_tech_rounded, size: 170, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.danger, size: 8),
                  const SizedBox(width: 4),
                  const Text('LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text(gameName.toUpperCase(),
                  style: const TextStyle(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                t != null ? t.title.toUpperCase() : 'SUMMER',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
              ),
              ShaderMask(
                shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
                child: const Text('CHAMPIONSHIP',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
              ),
              const SizedBox(height: 6),
              const Text('Win Exciting Prizes',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              GradientButton(label: 'Join Now', height: 40, onTap: onJoin),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRIZE POOL',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 13),
                      const SizedBox(width: 4),
                      Text('₹${formatMoney(t?.prizePool ?? 50000)}',
                          style: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('REGISTRATIONS',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(
                    t != null ? '${t.currentPlayers} / ${t.maxPlayers}' : '256 / 512',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    ('1', 'Register', 'Join tournament'),
    ('2', 'Compete', 'Play your matches'),
    ('3', 'Score', 'Top the leaderboard'),
    ('4', 'Win', 'Get exciting prizes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How It Works?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 18),
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              return const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 34),
                  child: _DashedLine(),
                ),
              );
            }
            final step = _steps[i ~/ 2];
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(step.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                Text(step.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                SizedBox(
                  width: 78,
                  child: Text(step.$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
              color: AppColors.purple.withValues(alpha: 0.5),
            );
          }),
        );
      },
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    );
  }
}

class _LiveTournamentCard extends StatelessWidget {
  final Tournament t;
  final String gameName;
  const _LiveTournamentCard({required this.t, required this.gameName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id))),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.circle, color: AppColors.danger, size: 8),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            Text(gameName.toUpperCase(),
                style: const TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            const SizedBox(height: 2),
            Text(t.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 12),
                          const SizedBox(width: 3),
                          Text('₹${formatMoney(t.prizePool)}',
                              style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Entries', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    Text('${t.currentPlayers} / ${t.maxPlayers}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 13),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text('Live now', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
                GradientButton(
                  label: 'Join',
                  height: 28,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTournamentCard extends StatelessWidget {
  final Tournament t;
  final String gameName;
  const _UpcomingTournamentCard({required this.t, required this.gameName});

  @override
  Widget build(BuildContext context) {
    final date = t.publishedAt;
    final dateLabel = date != null ? '${date.day} ${_month(date.month)}, ${date.year}' : 'TBA';
    final timeLabel = date != null
        ? '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}'
        : '--';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameIcon(game: gameName, size: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gameName.toUpperCase(),
                      style: const TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(dateLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                Text('₹${formatMoney(t.prizePool)}',
                    style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                GradientButton(
                  label: 'Join',
                  height: 30,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id))),
                ),
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
