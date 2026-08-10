import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/mock_data.dart';
import '../widgets/common.dart';
import 'tournament_detail_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _game = 'All';
  int _tabIndex = 0; // 0 upcoming, 1 live, 2 completed

  @override
  Widget build(BuildContext context) {
    final list = MockData.tournaments.where((t) {
      final gameMatch = _game == 'All' || t.game.toLowerCase() == _game.toLowerCase();
      final tabStatus = [TournamentStatus.upcoming, TournamentStatus.live, TournamentStatus.completed][_tabIndex];
      return gameMatch && t.status == tabStatus;
    }).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              children: [
                const Text('Tournaments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const Spacer(),
                _iconBtn(Icons.search_rounded),
                const SizedBox(width: 8),
                _iconBtn(Icons.tune_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: MockData.gameFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final g = MockData.gameFilters[i];
                final selected = g == _game;
                return GestureDetector(
                  onTap: () => setState(() => _game = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(g,
                        style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  final labels = ['Upcoming', 'Live', 'Completed'];
                  final selected = i == _tabIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.primaryGradient : null,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Text(labels[i],
                            style: TextStyle(
                                color: selected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('No tournaments found', style: TextStyle(color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    itemCount: list.length,
                    itemBuilder: (context, i) => TournamentListCard(
                      t: list[i],
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: list[i]))),
                      onJoin: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: list[i]))),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      );
}
