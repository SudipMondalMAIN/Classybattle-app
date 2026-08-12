import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/tournament_providers.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(tournamentSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final games = ref.read(gamesByIdProvider).valueOrNull?.values.toList() ?? [];
    final current = ref.read(tournamentGameFilterProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterSheet(
          games: games,
          selectedGameId: current,
          onSelected: (gameId) {
            ref.read(tournamentGameFilterProvider.notifier).state = gameId;
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(tournamentGameFilterProvider) != null;

    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search tournaments...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) => ref
                        .read(tournamentSearchQueryProvider.notifier)
                        .state = v,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _openFilters,
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            borderColor: activeFilter ? AppColors.purple : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: activeFilter ? AppColors.purpleSoft : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filters',
                  style: TextStyle(
                    color: activeFilter ? AppColors.purpleSoft : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.games,
    required this.selectedGameId,
    required this.onSelected,
  });

  final List<GameModel> games;
  final String? selectedGameId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by game',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('All games', null),
                for (final g in games) _chip(g.name, g.id),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? id) {
    final active = selectedGameId == id;
    return GestureDetector(
      onTap: () => onSelected(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.purple : AppColors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.purple : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
