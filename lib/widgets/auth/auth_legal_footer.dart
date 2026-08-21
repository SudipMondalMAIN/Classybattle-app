import 'package:flutter/material.dart';
import '../../content/legal_content.dart';
import '../../screens/legal_info_screen.dart';
import '../../theme/app_theme.dart';

/// "By continuing you accept our Terms & Conditions and Privacy Policy"
/// line shown at the bottom of the login/signup screens. The two policy
/// names are tappable and open the corresponding [LegalInfoScreen].
class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({super.key});

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalInfoScreen(
          title: 'Terms & Conditions',
          sections: termsSections,
          lastUpdated: 'August 2026',
        ),
      ),
    );
  }

  void _openPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalInfoScreen(
          title: 'Privacy Policy',
          sections: privacySections,
          lastUpdated: 'August 2026',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(color: AppColors.textMuted, fontSize: 12);
    const linkStyle = TextStyle(
      color: AppColors.purpleSoft,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('By continuing you accept our ', style: baseStyle),
          GestureDetector(
            onTap: () => _openTerms(context),
            child: const Text('Terms & Conditions', style: linkStyle),
          ),
          const Text(' & ', style: baseStyle),
          GestureDetector(
            onTap: () => _openPrivacy(context),
            child: const Text('Privacy Policy', style: linkStyle),
          ),
          const Text('.', style: baseStyle),
        ],
      ),
    );
  }
}
