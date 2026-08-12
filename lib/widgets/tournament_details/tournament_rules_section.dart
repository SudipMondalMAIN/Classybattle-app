import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TournamentRulesSection extends StatefulWidget {
  const TournamentRulesSection({super.key, required this.rules});

  /// Raw rules text from Tournament.rules on the backend. May contain
  /// newline-separated bullet points, or be null/empty if the
  /// organizer hasn't set any -- never fabricated.
  final String? rules;

  @override
  State<TournamentRulesSection> createState() => _TournamentRulesSectionState();
}

class _TournamentRulesSectionState extends State<TournamentRulesSection> {
  bool _expanded = false;

  List<String> get _bullets {
    final raw = widget.rules?.trim() ?? '';
    if (raw.isEmpty) return const [];
    return raw
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^[\s\-\*•]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bullets = _bullets;
    final visible = _expanded ? bullets : bullets.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.rule_folder_outlined, size: 18, color: AppColors.purpleSoft),
            SizedBox(width: 8),
            Text(
              'Tournament Rules',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (bullets.isEmpty)
          const Text(
            'No rules have been added for this tournament yet.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          )
        else ...[
          for (final b in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 5, color: AppColors.purple),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (bullets.length > 4)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Show Less' : 'View All Rules',
                      style: const TextStyle(
                        color: AppColors.purpleSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.chevron_right,
                      size: 16,
                      color: AppColors.purpleSoft,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
