import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

/// Fixed "Refer & Earn" promo banner shown near the bottom of the home
/// screen. Bundled static asset (same pattern as [FormatPageBanner]) --
/// not fetched from the backend /banners feed, not part of the hero
/// carousel, and doesn't swipe. Tapping it opens ReferEarnScreen.
class ReferEarnBanner extends StatelessWidget {
  const ReferEarnBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        // Matches the banner asset's own aspect ratio (roughly 2:1) so
        // the full design shows edge-to-edge instead of BoxFit.cover
        // cropping the character/text off a fixed-height box.
        child: AspectRatio(
          aspectRatio: 1774 / 887,
          child: GlassContainer(
            borderRadius: 16,
            blurSigma: 0,
            fillColor: AppColors.glassFillStrong,
            borderColor: AppColors.glassBorderBright,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/banners/refer_earn_banner.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.glassFillStrong,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
