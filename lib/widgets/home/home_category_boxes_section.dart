import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/home_category_box_model.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import '../common/skeleton.dart';
import 'home_category_box_card.dart';
import 'section_header.dart';

/// Admin-managed home-screen tap boxes -- 3 per row, same card design
/// as a live tournament card but fully static. Every non-Custom box
/// opens its own dedicated per-format browse page (solo/duo/squad/free/
/// cs_1v1/cs_head/cs_4v4/lw_1v1/lw_head/br_survive), same pattern as
/// Custom's own dedicated page; Custom routes into the user's own
/// tournament-creation flow.
class HomeCategoryBoxesSection extends ConsumerWidget {
  const HomeCategoryBoxesSection({
    super.key,
    required this.onFormatTap,
    required this.onCustomTap,
  });

  /// box_type name ("solo" | "duo" | "squad" | "free" | "cs_1v1" | ...)
  /// for the tapped box -- routes to that format's dedicated screen.
  final void Function(String format) onFormatTap;
  final VoidCallback onCustomTap;

  void _handleTap(HomeCategoryBoxModel box) {
    if (box.boxType == HomeCategoryBoxType.custom) {
      onCustomTap();
      return;
    }
    onFormatTap(box.boxType.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxesAsync = ref.watch(homeCategoryBoxesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Browse Tournaments'),
        ),
        const SizedBox(height: 14),
        boxesAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, i) => const SkeletonBox(
                height: double.infinity,
                borderRadius: 16,
              ),
            ),
          ),
          error: (e, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text(
              "Couldn't load categories",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          data: (boxes) {
            if (boxes.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: boxes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, i) {
                  final box = boxes[i];
                  return GestureDetector(
                    onTap: () => _handleTap(box),
                    child: HomeCategoryBoxCard(box: box),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
