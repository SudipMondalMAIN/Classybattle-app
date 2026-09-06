import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

/// Fixed promo banner shown at the top of the dedicated per-format browse
/// pages (Lone Wolf 1v1, CS 1v1, Solo, Squad, etc), in place of the search
/// bar those pages used to have.
///
/// Unlike the home screen's hero carousel, this is NOT fetched from the
/// backend /banners feed -- it's a bundled static asset, same pattern as
/// the app's avatar images (assets/avatars/avatar_N.png): declared in
/// pubspec.yaml, shipped inside the app, no network call, no loading
/// state. Falls back to a plain placeholder icon if the asset is missing
/// instead of crashing.
class FormatPageBanner extends StatelessWidget {
  const FormatPageBanner({
    super.key,
    required this.assetPath,
    this.aspectRatio = 1.8,
  });

  /// Bundled asset path, specific to the dedicated page it's shown on
  /// (e.g. CS 1v1's banner only ever appears on the CS 1v1 page --
  /// there's no cross-page carousel or shared rotation).
  final String assetPath;

  /// Width/height ratio of the actual banner artwork. Defaults to 1.8,
  /// matching the ~1.75-1.85 ratio common to this set of banners --
  /// sized this way (instead of a fixed height with BoxFit.cover) so
  /// the full image shows without its left/right edges being cropped.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GlassContainer(
        borderRadius: 16,
        blurSigma: 0,
        fillColor: AppColors.glassFillStrong,
        borderColor: AppColors.glassBorderBright,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.glassFillStrong,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.textMuted,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
