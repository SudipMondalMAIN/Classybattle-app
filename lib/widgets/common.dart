import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/tournament.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double? width;
  final double fontSize;
  final EdgeInsets padding;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 44,
    this.width,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          height: height,
          width: width,
          padding: padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const StatusPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
    );
  }
}

/// Maps a backend tournament `status` value to a display label + color.
class TournamentStatusStyle {
  final String label;
  final Color color;
  const TournamentStatusStyle(this.label, this.color);

  factory TournamentStatusStyle.of(String status) {
    switch (status) {
      case 'live':
        return const TournamentStatusStyle('LIVE', AppColors.danger);
      case 'completed':
        return const TournamentStatusStyle('COMPLETED', AppColors.textMuted);
      case 'cancelled':
        return const TournamentStatusStyle('CANCELLED', AppColors.textMuted);
      case 'scheduled':
      default:
        return const TournamentStatusStyle('REGISTRATION OPEN', AppColors.success);
    }
  }
}

class GameIcon extends StatelessWidget {
  final String game;
  final double size;
  const GameIcon({super.key, required this.game, this.size = 44});

  Color get _color {
    switch (game.toUpperCase()) {
      case 'BGMI':
        return AppColors.warning;
      case 'CODM':
        return AppColors.blue;
      case 'VALORANT':
        return AppColors.pink;
      default:
        return AppColors.danger;
    }
  }

  IconData get _icon {
    switch (game.toUpperCase()) {
      case 'BGMI':
        return Icons.military_tech_rounded;
      case 'CODM':
        return Icons.gps_fixed_rounded;
      case 'VALORANT':
        return Icons.grid_view_rounded;
      default:
        return Icons.local_fire_department_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Icon(_icon, color: _color, size: size * 0.5),
    );
  }
}

class SlotProgressBar extends StatelessWidget {
  final int filled;
  final int total;
  const SlotProgressBar({super.key, required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (filled / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 5,
        color: AppColors.surfaceLight,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio,
          child: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        ),
      ),
    );
  }
}

String formatMoney(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

class TournamentListCard extends StatelessWidget {
  final Tournament t;
  final String gameName;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool joined;

  const TournamentListCard({
    super.key,
    required this.t,
    required this.gameName,
    this.onTap,
    this.onJoin,
    this.joined = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = TournamentStatusStyle.of(t.status);
    final canJoin = t.status == 'scheduled' && !t.isFull && !joined;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GameIcon(game: gameName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gameName.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 2),
                      Text(t.title,
                          style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                StatusPill(
                    text: joined ? 'JOINED' : statusStyle.label,
                    color: joined ? AppColors.purple : statusStyle.color),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prize Pool',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹${formatMoney(t.prizePool)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Entry Fee',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹${formatMoney(t.entryFee)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Slots',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('${t.currentPlayers}/${t.maxPlayers}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                if (joined)
                  const StatusPill(text: 'JOINED', color: AppColors.purple)
                else
                  GradientButton(label: 'JOIN', onTap: canJoin ? onJoin : null, height: 36, fontSize: 12),
              ],
            ),
            const SizedBox(height: 10),
            SlotProgressBar(filled: t.currentPlayers, total: t.maxPlayers),
            const SizedBox(height: 4),
            Text('${t.currentPlayers}/${t.maxPlayers} slots filled',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
