import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class WalletSummaryGrid extends StatelessWidget {
  const WalletSummaryGrid({super.key, required this.summary});

  /// Null while loading/signed-out -- cards show a placeholder dash
  /// instead of a fake number.
  final WalletSummary? summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        icon: Icons.arrow_downward_rounded,
        iconColor: AppColors.success,
        iconBg: const Color(0xFF15321F),
        label: 'Total Added',
        value: summary?.totalAdded,
      ),
      _SummaryItem(
        icon: Icons.arrow_upward_rounded,
        iconColor: AppColors.purpleSoft,
        iconBg: const Color(0xFF2A2050),
        label: 'Total Used',
        value: summary?.totalUsed,
      ),
      _SummaryItem(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: AppColors.gold,
        iconBg: const Color(0xFF3A2A0E),
        label: 'Winning',
        value: summary?.totalWinnings,
      ),
      _SummaryItem(
        icon: Icons.card_giftcard_rounded,
        iconColor: const Color(0xFF6FA8FF),
        iconBg: const Color(0xFF11253F),
        label: 'Bonus',
        value: summary?.totalBonus,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 4 columns on normal phone widths; drops to a 2x2 grid only
        // if the available width is unusually narrow, so nothing ever
        // overflows regardless of device size.
        final fourAcross = constraints.maxWidth >= 340;
        if (fourAcross) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: items[i]),
              ],
            ],
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: items,
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value == null ? '—' : formatRupees(value!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
