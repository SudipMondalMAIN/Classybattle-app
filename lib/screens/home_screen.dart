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
import 'tournament_detail_screen.dart';
import 'tournaments_screen.dart';

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
        GameCache.instance.byId(),
        _walletService.getWallet(),
      ]);
      if (!mounted) return;
      setState(() {
        _live = results[0] as List<Tournament>;
        _featured = results[1] as List<Tournament>;
        _games = results[2] as Map<String, Game>;
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

  String _gameName(String gameId) => _games[gameId]?.name ?? 'Unknown';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
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
            _buildTopBar(),
            const SizedBox(height: 18),
            _buildGreeting(user?.fullName),
            const SizedBox(height: 18),
            _buildBanner(),
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
              ..._live.map((t) => _LiveTournamentCard(t: t, gameName: _gameName(t.gameId))),
            const SizedBox(height: 10),
            SectionHeader(
              title: 'Featured Tournaments',
              action: 'View All',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen())),
            ),
            const SizedBox(height: 12),
            if (_featured.isEmpty)
              const _EmptyRow(text: 'No featured tournaments right now')
            else
              ..._featured.map((t) => _FeaturedTournamentCard(t: t, gameName: _gameName(t.gameId))),
          ],
        ),
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

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 10),
        const Text('ClassyBattle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 20),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text('₹${formatMoney(_walletBalance ?? 0)}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildGreeting(String? fullName) {
    final displayName = (fullName == null || fullName.trim().isEmpty) ? 'Player' : fullName.split(' ').first;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, $displayName 👋',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Text('Welcome back!', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: 4,
            itemBuilder: (context, i) => Container(
              margin: const EdgeInsets.only(right: 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3A1A6B), Color(0xFF1A1330)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLASSYBATTLE',
                      style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ShaderMask(
                    shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
                    child: const Text('COMPETE',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  ),
                  const Text('& WIN BIG',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const Spacer(),
                  GradientButton(
                    label: 'EXPLORE',
                    height: 36,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen())),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            GameIcon(game: gameName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, color: AppColors.danger, size: 8),
                      const SizedBox(width: 4),
                      const Text('LIVE', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text(gameName, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Prize Pool ₹${formatMoney(t.prizePool)}   Entry Fee ₹${formatMoney(t.entryFee)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${t.currentPlayers}/${t.maxPlayers}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                GradientButton(
                  label: 'VIEW',
                  height: 32,
                  fontSize: 11,
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

class _FeaturedTournamentCard extends StatelessWidget {
  final Tournament t;
  final String gameName;
  const _FeaturedTournamentCard({required this.t, required this.gameName});

  @override
  Widget build(BuildContext context) {
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
          children: [
            GameIcon(game: gameName, size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(gameName, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                Text('₹${formatMoney(t.prizePool)}', style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Entry ₹${formatMoney(t.entryFee)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
