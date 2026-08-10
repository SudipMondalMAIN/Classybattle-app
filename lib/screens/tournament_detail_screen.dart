import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/mock_data.dart';
import '../widgets/common.dart';

class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;
  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  int _tab = 0;
  final _tabs = ['Details', 'Rules', 'Prize', 'Participants'];

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHero(t),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prize Pool', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            Text('₹${t.prizePool}',
                                style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Entry Fee', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            Text('₹${t.entryFee}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        _infoStat(Icons.map_rounded, t.map),
                        _divider(),
                        _infoStat(Icons.groups_rounded, t.mode),
                        _divider(),
                        _infoStat(Icons.person_rounded, '${t.playersPerTeam} Players'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailRow('Starts In', t.startsIn),
                  _detailRow('Registration Ends', t.registrationEnds),
                  _detailRow('Tournament Starts', t.tournamentStarts),
                  _detailRow('Type', t.type),
                  const SizedBox(height: 18),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildTabContent(t),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: GradientButton(label: 'JOIN TOURNAMENT', height: 52, width: double.infinity, fontSize: 15, onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined tournament!'), backgroundColor: AppColors.purple),
          );
        }),
      ),
    );
  }

  Widget _infoStat(IconData icon, String label) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppColors.purple, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 34, color: AppColors.cardBorder);

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildHero(Tournament t) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1760), Color(0xFF120B26)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [AppColors.purple.withValues(alpha: 0.35), Colors.transparent],
                  radius: 0.9,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleIcon(Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                Row(children: [
                  _circleIcon(Icons.favorite_border_rounded),
                  const SizedBox(width: 8),
                  _circleIcon(Icons.share_rounded),
                ]),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.game,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text(t.title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (i) {
        final selected = i == _tab;
        return Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Column(
              children: [
                Text(_tabs[i],
                    style: TextStyle(
                        color: selected ? AppColors.purple : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (selected)
                  Container(width: 20, height: 2, decoration: BoxDecoration(gradient: AppColors.primaryGradient)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabContent(Tournament t) {
    switch (_tab) {
      case 1:
        return const Text(
          '• No teaming allowed\n• Use of hacks/mods leads to ban\n• Screenshots required after match\n• Follow fair play guidelines',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.8),
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _PrizeRow(place: '🥇 1st Place', amount: '₹5,000'),
            _PrizeRow(place: '🥈 2nd Place', amount: '₹3,000'),
            _PrizeRow(place: '🥉 3rd Place', amount: '₹2,000'),
          ],
        );
      case 3:
        return Text('${t.slotsFilled} teams registered out of ${t.slotsTotal} slots.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6));
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About Tournament',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(t.about, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.7)),
          ],
        );
    }
  }
}

class _PrizeRow extends StatelessWidget {
  final String place;
  final String amount;
  const _PrizeRow({required this.place, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(place, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          Text(amount, style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
