import 'package:flutter/material.dart';
import '../../models/home_category_box_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import '../common/network_image_box.dart';

/// A single home-screen category box (Solo / Squad / Custom
/// Tournament). Same card shape/design as [LiveTournamentCard] --
/// banner image + title -- but fully static/admin-set content, no
/// live tournament stats. Sized to sit 3-per-row in a grid.
class HomeCategoryBoxCard extends StatelessWidget {
  const HomeCategoryBoxCard({super.key, required this.box});

  final HomeCategoryBoxModel box;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      // Same reasoning as LiveTournamentCard -- this renders 3-per-row
      // in a grid, so skip the per-card blur pass.
      blurSigma: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 600 / 410,
            child: NetworkImageBox(
              url: box.bannerUrl,
              fit: BoxFit.cover,
              cacheWidth: 300,
              cacheHeight: 205,
            ),
          ),
          if (box.title != null && box.title!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                box.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
