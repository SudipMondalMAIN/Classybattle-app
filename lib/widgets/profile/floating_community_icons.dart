import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

/// Wraps [child] and overlays a small vertical stack of floating
/// community-link icon buttons (Telegram, WhatsApp) above the
/// bottom-right corner. Tapping one opens the corresponding channel in
/// an external app/browser via url_launcher.
class FloatingCommunityIcons extends StatelessWidget {
  const FloatingCommunityIcons({super.key, required this.child});

  final Widget child;

  static const List<_CommunityLink> _links = [
    _CommunityLink(
      icon: FontAwesomeIcons.telegram,
      url: 'https://t.me/ClassyBattleOnline',
      color: Color(0xFF29A9EA),
    ),
    _CommunityLink(
      icon: FontAwesomeIcons.whatsapp,
      url: 'https://whatsapp.com/channel/0029VbDEgzJBKfhwKgnWun2r',
      color: Color(0xFF25D366),
    ),
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 14,
          bottom: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final link in _links) ...[
                _CommunityIconButton(link: link, onTap: () => _open(link.url)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CommunityLink {
  const _CommunityLink({
    required this.icon,
    required this.url,
    required this.color,
  });

  final IconData icon;
  final String url;
  final Color color;
}

class _CommunityIconButton extends StatelessWidget {
  const _CommunityIconButton({required this.link, required this.onTap});

  final _CommunityLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background.withValues(alpha: 0.85),
            border: Border.all(color: AppColors.glassBorderBright),
            boxShadow: [
              BoxShadow(
                color: link.color.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: FaIcon(link.icon, color: link.color, size: 20),
        ),
      ),
    );
  }
}