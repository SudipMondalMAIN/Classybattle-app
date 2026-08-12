import 'package:flutter/material.dart';
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
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final imageUrl = url;

    Widget content;
    if (imageUrl == null || imageUrl.isEmpty) {
      content = _placeholder(icon: Icons.image_outlined);
    } else {
      content = Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(
            icon: null,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.purpleSoft,
                value: progress.expectedTotalBytes != null
                    ? (progress.cumulativeBytesLoaded /
                          (progress.expectedTotalBytes ?? 1))
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
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
