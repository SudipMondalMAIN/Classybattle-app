import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

/// Wraps [Image.network] with a real loading indicator and a real
/// error state (broken-image icon), so a missing/failed backend
/// image never gets silently swapped for stock/dummy artwork.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Target decode size in logical px. Always set these to the widget's
  /// actual display size — without them, cached_network_image decodes
  /// the source image at FULL resolution into RAM, even if it's shown
  /// tiny on screen. This is the single biggest RAM cost for images.
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final imageUrl = url;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    Widget content;
    if (imageUrl == null || imageUrl.isEmpty) {
      content = _placeholder(icon: Icons.image_outlined);
    } else {
      content = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 120),
        memCacheWidth: cacheWidth != null
            ? (cacheWidth! * dpr).round()
            : null,
        memCacheHeight: cacheHeight != null
            ? (cacheHeight! * dpr).round()
            : null,
        placeholder: (context, url) => _placeholder(
          icon: null,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.purpleSoft,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return _placeholder(icon: Icons.broken_image_outlined);
        },
      );
    }

    return ClipRRect(borderRadius: radius, child: content);
  }

  Widget _placeholder({IconData? icon, Widget? child}) {
    return Container(
      color: AppColors.glassFillStrong,
      alignment: Alignment.center,
      child:
          child ??
          Icon(icon, color: AppColors.textMuted, size: 26),
    );
  }
}
