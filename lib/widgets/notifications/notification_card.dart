import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';
import '../common/glass_container.dart';
import 'notification_meta.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = NotificationMeta.of(notification.eventType);
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.all(14),
          blurSigma: 0, // per-row card in a scrolling list -- see live_tournament_card.dart
          fillColor: unread
              ? AppColors.glassFillStrong
              : Colors.white.withValues(alpha: 0.04),
          borderColor:
              unread ? AppColors.glassBorderBright : AppColors.glassBorder,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: meta.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, color: meta.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: highlightedBody(
                          notification.body,
                          entityColor: meta.iconColor == AppColors.live
                              ? AppColors.live
                              : AppColors.purpleSoft,
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatRelativeTime(notification.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
