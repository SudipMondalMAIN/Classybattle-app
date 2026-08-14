import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/home_category_box_model.dart';
import '../../providers/home_providers.dart';
import '../../theme/app_theme.dart';
import 'home_category_box_card.dart';
import 'section_header.dart';

/// Admin-managed home-screen tap boxes -- 3 per row, same card design
/// as a live tournament card but fully static. Solo/Squad boxes filter
/// the tournament list by game + category; Custom routes into the
/// user's own tournament-creation flow.
class HomeCategoryBoxesSection extends ConsumerWidget {
  const HomeCategoryBoxesSection({
    super.key,
    required this.onSoloOrSquadTap,
    required this.onCustomTap,
  });

  /// gameId + category ("solo" | "squad") for the tapped box.
  final void Function(String gameId, String category) onSoloOrSquadTap;
  final VoidCallback onCustomTap;

  void _handleTap(HomeCategoryBoxModel box) {
    if (box.boxType == HomeCategoryBoxType.custom) {
      onCustomTap();
      return;
    }
    final gameId = box.gameId;
    if (gameId == null) return; // shouldn't happen -- backend enforces this
    onSoloOrSquadTap(gameId, box.boxType.name);
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
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.purpleSoft),
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
