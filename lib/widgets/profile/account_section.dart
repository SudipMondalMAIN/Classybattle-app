import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';

class AccountRow {
  const AccountRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailingBadge,
    this.iconColor,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final String? trailingBadge;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;
}

/// A glass card containing a vertical list of rows with dividers,
/// matching the reference Account section style. Used by both the
/// Profile screen's Account list and the Settings screen's sections.
class AccountSectionCard extends StatelessWidget {
  const AccountSectionCard({super.key, required this.rows});

  final List<AccountRow> rows;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              InkWell(
                onTap: row.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(row.icon,
                          size: 20,
                          color: row.iconColor ?? AppColors.textSecondary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (row.trailingText != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            row.trailingText!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (row.trailingBadge != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.glassFillStrong,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.glassBorderBright),
                          ),
                          child: Text(
                            row.trailingBadge!,
                            style: const TextStyle(
                              color: AppColors.purpleSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (row.trailing != null) row.trailing!,
                      if (row.trailing == null)
                        const Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (i != rows.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.glassBorder,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }
}
