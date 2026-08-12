import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tournament_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class TournamentTabsBar extends ConsumerWidget {
  const TournamentTabsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTournamentTabProvider);
    final liveCount = ref.watch(liveTournamentsCountProvider).valueOrNull;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final tab in TournamentTab.values) ...[
            _TabChip(
              tab: tab,
              active: tab == selected,
              badge: tab == TournamentTab.live ? liveCount : null,
              onTap: () =>
                  ref.read(selectedTournamentTabProvider.notifier).state = tab,
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final TournamentTab tab;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: active
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.purpleButton,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _label(Colors.white),
            )
          : GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: _label(AppColors.textSecondary),
            ),
    );
  }

  Widget _label(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tab.label,
          style: TextStyle(
            color: color,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.live,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
