import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

/// Wraps [child] and overlays a small, draggable floating pill holding
/// the community-link icon buttons (Telegram, WhatsApp). Tapping one
/// opens the corresponding channel in an external app/browser via
/// url_launcher. The pill can be dragged anywhere on screen and stays
/// there for the life of this widget; it's clamped so it can never be
/// dragged off-screen or behind the bottom nav bar.
class FloatingCommunityIcons extends StatefulWidget {
  const FloatingCommunityIcons({super.key, required this.child});

  final Widget child;

  @override
  State<FloatingCommunityIcons> createState() =>
      _FloatingCommunityIconsState();
}

class _FloatingCommunityIconsState extends State<FloatingCommunityIcons> {
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

  // Position of the pill's top-left corner. Null until the first
  // layout, when it's seeded to the original bottom-right resting
  // spot; drag updates it directly.
  Offset? _pos;

  static const double _pillWidth = 52;
  double get _pillHeight => 16 + _links.length * 44 + (_links.length - 1) * 10;

  Offset _clamp(Offset offset, Size screen, EdgeInsets safe) {
    final maxX = screen.width - _pillWidth - 8;
    final maxY = screen.height - _pillHeight - safe.bottom - 8;
    final minX = 8.0;
    final minY = safe.top + 8;
    return Offset(
      offset.dx.clamp(minX, maxX < minX ? minX : maxX),
      offset.dy.clamp(minY, maxY < minY ? minY : maxY),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) _showFailedSnack();
    } catch (_) {
      // Some devices throw instead of returning false (e.g. no activity
      // found for the intent) -- fall back to an in-app browser view so
      // a tap never just silently does nothing.
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        if (mounted) _showFailedSnack();
      }
    }
  }

  void _showFailedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final safe = MediaQuery.of(context).padding;
    _pos ??= _clamp(
      Offset(screen.width - _pillWidth - 14, screen.height - _pillHeight - 110),
      screen,
      safe,
    );

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _pos!.dx,
          top: _pos!.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _pos = _clamp(_pos! + details.delta, screen, safe);
              });
            },
            child: _CommunityPill(links: _links, onTap: _open),
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

/// The draggable handle itself: a single rounded-pill glass surface
/// holding every icon stacked vertically, instead of separate floating
/// circles -- one coherent shape rather than a couple of loose dots.
class _CommunityPill extends StatelessWidget {
  const _CommunityPill({required this.links, required this.onTap});

  final List<_CommunityLink> links;
  final void Function(String url) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.glassBorderBright),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < links.length; i++) ...[
            _CommunityIconButton(
              link: links[i],
              onTap: () => onTap(links[i].url),
            ),
            if (i != links.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
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
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: link.color.withValues(alpha: 0.16),
          ),
          child: FaIcon(link.icon, color: link.color, size: 18),
        ),
      ),
    );
  }
}
