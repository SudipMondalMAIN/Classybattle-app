import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A single looping shimmer animation shared by every [SkeletonBox] in
/// its subtree, so all skeleton placeholders on a screen sweep in sync
/// instead of drifting out of phase with each other.
class Skeletonizer extends StatefulWidget {
  const Skeletonizer({super.key, required this.child});

  final Widget child;

  @override
  State<Skeletonizer> createState() => _SkeletonizerState();
}

class _SkeletonizerState extends State<Skeletonizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SkeletonScope(animation: _controller, child: widget.child);
  }
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SkeletonScope>()
        ?.animation;
  }

  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) => false;
}

/// A shimmering rounded-rect placeholder. Drop these in wherever a
/// spinner used to sit, shaped like the content that will replace them
/// (a line of text, an avatar circle, a card, an image box, ...).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  /// Convenience constructor for a circular placeholder (avatars, icons).
  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;

  Animation<double> get _animation =>
      _SkeletonScope.maybeOf(context) ??
      (_localController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat());

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Sweep a soft highlight left-to-right across the base tone.
        final t = animation.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - t * 2, 0),
              end: Alignment(1.0 - t * 2, 0),
              colors: const [
                AppColors.glassFill,
                AppColors.glassFillStrong,
                AppColors.glassFill,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
