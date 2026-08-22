import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../models/banner_model.dart';
import '../../models/tournament_model.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../common/network_image_box.dart';

/// Large hero banner: PageView of real /banners images, with the
/// real featured-live-tournament stats (LIVE badge, game, title,
/// prize pool, registrations) overlaid on top -- exactly like the
/// reference, but every value shown comes from the backend.
class HeroBannerCarousel extends ConsumerStatefulWidget {
  const HeroBannerCarousel({super.key, required this.onJoinTap});

  final void Function(TournamentModel? featured) onJoinTap;

  @override
  ConsumerState<HeroBannerCarousel> createState() =>
      _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends ConsumerState<HeroBannerCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final featuredAsync = ref.watch(featuredLiveTournamentProvider);
    final gamesAsync = ref.watch(gamesByIdProvider);

    return bannersAsync.when(
      loading: () => const _HeroSkeleton(),
      error: (e, __) => const _HeroError(),
      data: (banners) {
        if (banners.isEmpty) {
          return const _HeroEmpty();
        }
        return Column(
          children: [
            AspectRatio(
              aspectRatio: 775 / 370,
              child: GlassContainer(
                borderRadius: 24,
                blurSigma: 0,
                fillColor: Colors.transparent,
                borderColor: AppColors.glassBorderBright,
                glow: true,
                padding: EdgeInsets.zero,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Decode at the banner's actual on-screen size --
                    // a hardcoded guess here would under-decode (blurry
                    // upscale) on wider screens or over-decode (wasted
                    // memory) on narrow ones.
                    final w = constraints.maxWidth.round();
                    final h = constraints.maxHeight.round();
                    return PageView.builder(
                      controller: _controller,
                      itemCount: banners.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        return _HeroSlide(
                          banner: banners[i],
                          featured: featuredAsync.valueOrNull,
                          gameName: gamesAsync.valueOrNull != null &&
                                  featuredAsync.valueOrNull != null
                              ? gamesAsync.valueOrNull![
                                      featuredAsync.valueOrNull!.gameId]
                                  ?.name
                              : null,
                          onJoinTap: () =>
                              widget.onJoinTap(featuredAsync.valueOrNull),
                          cacheWidth: w,
                          cacheHeight: h,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Indicators(count: banners.length, activeIndex: _index),
          ],
        );
      },
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({
    required this.banner,
    required this.featured,
    required this.gameName,
    required this.onJoinTap,
    required this.cacheWidth,
    required this.cacheHeight,
  });

  final BannerModel banner;
  final TournamentModel? featured;
  final String? gameName;
  final VoidCallback onJoinTap;
  final int cacheWidth;
  final int cacheHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: featured != null ? onJoinTap : null,
      child: Stack(
      fit: StackFit.expand,
      children: [
        NetworkImageBox(
          url: banner.imageUrl,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        ),
        // Dark gradient overlay so text stays legible over any artwork --
        // kept tight to the bottom third where the text/CTA actually
        // sits, instead of washing the whole banner in a translucent
        // black tint (which read as "hazy/blurry" even though no actual
        // blur filter was applied).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.45, 0.75, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (featured != null && featured!.isLive) const _LiveBadge(),
              if (featured != null) ...[
                const SizedBox(height: 10),
                if (gameName != null)
                  Text(
                    gameName!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.purpleSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  featured!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'Win Exciting Prizes',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _EntryFeePill(entryFee: featured!.entryFee),
                  ],
                ),
                // Once a tournament goes live, joining is closed --
                // so the CTA disappears instead of staying tappable.
                if (!featured!.isLive) ...[
                  const SizedBox(height: 14),
                  _JoinButton(onTap: onJoinTap),
                ],
              ] else if (banner.title != null) ...[
                Text(
                  banner.title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (featured != null)
          Positioned(
            top: 18,
            right: 18,
            child: _PrizePanel(featured: featured!),
          ),
      ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.live),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryFeePill extends StatelessWidget {
  const _EntryFeePill({required this.entryFee});
  final double entryFee;

  @override
  Widget build(BuildContext context) {
    final isFree = entryFee <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFree
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.gold.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        isFree ? 'FREE ENTRY' : 'Entry ${formatRupees(entryFee)}',
        style: TextStyle(
          color: isFree ? AppColors.success : AppColors.gold,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.purpleButton,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Join Now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _PrizePanel extends StatelessWidget {
  const _PrizePanel({required this.featured});

  final TournamentModel featured;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      fillColor: Colors.black.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            featured.prizeType == 'per_kill'
                ? 'PER KILL'
                : featured.prizeType == 'win'
                    ? 'WIN BONUS'
                    : 'PRIZE POOL',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, size: 15, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                featured.prizeType == 'per_kill'
                    ? '${formatCount(featured.prizeBadgeAmount)}/kill'
                    : formatCount(featured.prizeBadgeAmount),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'REGISTRATIONS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${formatCount(featured.currentPlayers)} / ${formatCount(featured.maxPlayers)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.textPrimary : AppColors.textMuted,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 775 / 370,
      child: GlassContainer(
        borderRadius: 24,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.purpleSoft),
        ),
      ),
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 775 / 370,
      child: GlassContainer(
        borderRadius: 24,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 28),
              SizedBox(height: 8),
              Text(
                'Couldn\'t load banners',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroEmpty extends StatelessWidget {
  const _HeroEmpty();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 775 / 370,
      child: GlassContainer(
        borderRadius: 24,
        child: const Center(
          child: Text(
            'No banners yet',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
