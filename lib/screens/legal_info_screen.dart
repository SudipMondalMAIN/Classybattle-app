import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One heading + body block within a [LegalInfoScreen].
class InfoSection {
  const InfoSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// Generic scrollable "legal/info" screen: a title, an optional
/// last-updated line, and a list of heading+body sections. Used for
/// About ClassyBattle, Terms & Conditions, and Privacy Policy so all
/// three share one consistent, readable layout instead of a cramped
/// dialog box.
class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({
    super.key,
    required this.title,
    required this.sections,
    this.lastUpdated,
  });

  final String title;
  final List<InfoSection> sections;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientTop,
              AppColors.backgroundGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    if (lastUpdated != null) ...[
                      Text(
                        'Last updated: $lastUpdated',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    for (final section in sections) ...[
                      Text(
                        section.heading,
                        style: const TextStyle(
                          color: AppColors.purpleSoft,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
