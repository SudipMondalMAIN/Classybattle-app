import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A pulsing placeholder block — used to build skeleton loading screens
/// instead of a plain spinner, so the layout shape is visible while data loads.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width = double.infinity, this.height = 14, this.radius = 8});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final color = Color.lerp(AppColors.surfaceLight, AppColors.cardBorder, t)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(widget.radius)),
        );
      },
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, radius: size / 2);
  }
}

/// A generic row skeleton (avatar/icon + two text lines) — used for
/// leaderboard rows, wallet transactions, tournament list rows, etc.
class SkeletonListTile extends StatelessWidget {
  final double leadingSize;
  final bool leadingCircle;
  const SkeletonListTile({super.key, this.leadingSize = 44, this.leadingCircle = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          leadingCircle
              ? SkeletonCircle(size: leadingSize)
              : SkeletonBox(width: leadingSize, height: leadingSize, radius: AppRadius.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox(width: 50, height: 20, radius: AppRadius.pill),
        ],
      ),
    );
  }
}

/// A full-page skeleton: N list-tile rows.
class SkeletonListPage extends StatelessWidget {
  final int count;
  final EdgeInsets padding;
  final bool leadingCircle;
  const SkeletonListPage({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.fromLTRB(18, 0, 18, 20),
    this.leadingCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: count,
      itemBuilder: (context, i) => SkeletonListTile(leadingCircle: leadingCircle),
    );
  }
}
