import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'my_tournaments_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        children: [
          Row(
            children: [
              const Text('Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Icon(Icons.settings_rounded, color: AppColors.textPrimary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sudip',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    Row(
                      children: [
                        const Text('UID: 9284729', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Level 18', style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Text('3600/5000', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 5,
                        color: AppColors.surfaceLight,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.72,
                          child: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                _stat('245', 'Matches'),
                _vDivider(),
                _stat('61', 'Wins'),
                _vDivider(),
                _stat('24.9%', 'Win Rate'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _menuItem(context, Icons.emoji_events_rounded, 'My Tournaments',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTournamentsScreen()))),
          _menuItem(context, Icons.groups_rounded, 'My Team'),
          _menuItem(context, Icons.account_balance_wallet_rounded, 'Wallet'),
          _menuItem(context, Icons.star_rounded, 'Achievements'),
          _menuItem(context, Icons.settings_rounded, 'Settings'),
          _menuItem(context, Icons.help_outline_rounded, 'Support'),
          _menuItem(context, Icons.logout_rounded, 'Logout', danger: true),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      );

  Widget _vDivider() => Container(width: 1, height: 34, color: AppColors.cardBorder);

  Widget _menuItem(BuildContext context, IconData icon, String label, {bool danger = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: danger ? AppColors.danger : AppColors.purple, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: danger ? AppColors.danger : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
