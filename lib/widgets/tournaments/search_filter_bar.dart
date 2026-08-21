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
    final currentGame = ref.read(tournamentGameFilterProvider);
    final currentFormat = ref.read(tournamentCategoryFilterProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _FilterSheet(
          games: games,
          selectedGameId: currentGame,
          selectedFormat: currentFormat,
          onGameSelected: (gameId) {
            ref.read(tournamentGameFilterProvider.notifier).state = gameId;
          },
          onFormatSelected: (format) {
            ref.read(tournamentCategoryFilterProvider.notifier).state = format;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(tournamentGameFilterProvider) != null ||
        ref.watch(tournamentCategoryFilterProvider) != null;

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

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.games,
    required this.selectedGameId,
    required this.selectedFormat,
    required this.onGameSelected,
    required this.onFormatSelected,
  });

  final List<GameModel> games;
  final String? selectedGameId;
  final String? selectedFormat;
  final ValueChanged<String?> onGameSelected;
  final ValueChanged<String?> onFormatSelected;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const _formats = [
    ('All', null),
    ('Solo', 'solo'),
    ('Duo', 'duo'),
    ('Squad', 'squad'),
    ('Free', 'free'),
    ('Custom', 'custom'),
  ];

  late String? _gameId = widget.selectedGameId;
  late String? _format = widget.selectedFormat;

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
              'Format',
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
                for (final f in _formats)
                  _chip(f.$1, f.$2, _format == f.$2, () {
                    setState(() => _format = f.$2);
                  }),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Game',
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
                _chip('All games', null, _gameId == null, () {
                  setState(() => _gameId = null);
                }),
                for (final g in widget.games)
                  _chip(g.name, g.id, _gameId == g.id, () {
                    setState(() => _gameId = g.id);
                  }),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onGameSelected(_gameId);
                  widget.onFormatSelected(_format);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? value, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
