import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_providers.dart';

/// Wraps the whole app (see MaterialApp.builder in main.dart) and
/// overlays a slim status bar on top of whatever screen is currently
/// showing:
///  - offline           -> persistent red "No internet connection" bar
///  - offline -> online -> brief green "Back online" bar, auto-hides
///
/// Purely reactive to [connectivityProvider] -- no polling of its
/// own and no calls to our backend; the underlying check is a DNS
/// lookup against a public resolver (see ConnectivityService), so
/// this never adds server load no matter how often the network
/// flaps.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ConnectivityBanner> createState() =>
      _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  bool _showBackOnline = false;
  bool? _prevOnline;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectivityProvider);

    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      final online = next.valueOrNull;
      if (online == null) return;
      if (_prevOnline == false && online == true) {
        setState(() => _showBackOnline = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showBackOnline = false);
        });
      }
      _prevOnline = online;
    });

    final isOffline = status.valueOrNull == false;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: isOffline
              ? const _StatusBar(
                  color: Color(0xFFC0392B),
                  icon: Icons.wifi_off_rounded,
                  text: 'No internet connection',
                )
              : (_showBackOnline
                  ? const _StatusBar(
                      color: Color(0xFF27AE60),
                      icon: Icons.wifi_rounded,
                      text: 'Back online',
                    )
                  : const SizedBox(width: double.infinity, height: 0)),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: color,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
