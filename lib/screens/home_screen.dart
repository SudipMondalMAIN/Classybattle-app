import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/mock_data.dart';
import '../widgets/common.dart';
import 'tournament_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final live = MockData.tournaments.where((t) => t.status == TournamentStatus.live).toList();
    final featured = MockData.tournaments.take(3).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        children: [
          _buildTopBar(),
          const SizedBox(height: 18),
          _buildGreeting(),
          const SizedBox(height: 18),
          _buildBanner(),
          const SizedBox(height: 22),
          SectionHeader(title: 'Live Tournaments', action: 'View All', onAction: () {}),
          const SizedBox(height: 12),
          ...live.map((t) => _LiveTournamentCard(t: t)),
          const SizedBox(height: 10),
          SectionHeader(title: 'Featured Tournaments', action: 'View All', onAction: () {}),
          const SizedBox(height: 12),
          ...featured.map((t) => _FeaturedTournamentCard(t: t)),
        ],
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
          child: const Text('₹520.00',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, Sudip 👋',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('Welcome back!', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                  const Text('FREE FIRE',
                      style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ShaderMask(
                    shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
                    child: const Text('MEGA',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  ),
                  const Text('TOURNAMENT',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  const Text('PRIZE POOL', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  const Text('₹25,000',
                      style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GradientButton(label: 'JOIN NOW', height: 36, onTap: () {}),
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

class _LiveTournamentCard extends StatelessWidget {
  final Tournament t;
  const _LiveTournamentCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: t))),
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
            GameIcon(game: t.game),
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
                      Text(t.game, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Prize Pool ₹${t.prizePool}   Entry Fee ₹${t.entryFee}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${t.slotsFilled}/${t.slotsTotal}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                GradientButton(label: 'JOIN', height: 32, fontSize: 11, onTap: () {}),
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
  const _FeaturedTournamentCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: t))),
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
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(t.game,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(t.game, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                Text('₹${t.prizePool}', style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Entry ₹${t.entryFee}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
