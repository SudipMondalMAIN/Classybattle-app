import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';

/// Derives an icon + accent color for a notification from its real
/// `event_type` — mirrors TransactionMeta's pattern in the wallet widgets.
class NotificationMeta {
  const NotificationMeta({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  factory NotificationMeta.of(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.registrationSuccessful:
        return const NotificationMeta(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          iconBg: Color(0xFF15321F),
        );
      case NotificationEventType.registrationCancelled:
      case NotificationEventType.tournamentCancelled:
        return const NotificationMeta(
          icon: Icons.cancel_rounded,
          iconColor: AppColors.live,
          iconBg: Color(0xFF3A1414),
        );
      case NotificationEventType.tournamentCreated:
      case NotificationEventType.winnerDeclared:
        return const NotificationMeta(
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.purpleSoft,
          iconBg: Color(0xFF2A2050),
        );
      case NotificationEventType.prizeDistributed:
        return const NotificationMeta(
          icon: Icons.card_giftcard_rounded,
          iconColor: AppColors.gold,
          iconBg: Color(0xFF3A2A0E),
        );
      case NotificationEventType.tournamentUpdated:
      case NotificationEventType.matchStarted:
      case NotificationEventType.liveMatchStarted:
        return const NotificationMeta(
          icon: Icons.groups_rounded,
          iconColor: Color(0xFF6EA8FE),
          iconBg: Color(0xFF122A4A),
        );
      case NotificationEventType.roomDetailsPublished:
        return const NotificationMeta(
          icon: Icons.meeting_room_rounded,
          iconColor: Color(0xFF6EA8FE),
          iconBg: Color(0xFF122A4A),
        );
      case NotificationEventType.walletCredited:
      case NotificationEventType.refundCompleted:
        return const NotificationMeta(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.purpleSoft,
          iconBg: Color(0xFF2A2050),
        );
      case NotificationEventType.walletDebited:
        return const NotificationMeta(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.live,
          iconBg: Color(0xFF3A1414),
        );
      case NotificationEventType.matchCompleted:
      case NotificationEventType.matchResultApproved:
        return const NotificationMeta(
          icon: Icons.star_rounded,
          iconColor: AppColors.success,
          iconBg: Color(0xFF15321F),
        );
      case NotificationEventType.matchCreated:
        return const NotificationMeta(
          icon: Icons.notifications_active_rounded,
          iconColor: AppColors.gold,
          iconBg: Color(0xFF3A2A0E),
        );
      case NotificationEventType.userRegistration:
        return const NotificationMeta(
          icon: Icons.person_rounded,
          iconColor: AppColors.purpleSoft,
          iconBg: Color(0xFF2A2050),
        );
      case NotificationEventType.adminBroadcast:
      case NotificationEventType.systemAnnouncement:
      case NotificationEventType.general:
        return const NotificationMeta(
          icon: Icons.notifications_rounded,
          iconColor: AppColors.textSecondary,
          iconBg: Color(0xFF23222E),
        );
    }
  }
}

/// Highlights ₹ amounts and quoted entity names ('tournament title') within
/// a notification body, matching the reference design's colored inline
/// emphasis — built purely from the real body text, nothing hardcoded.
List<TextSpan> highlightedBody(String text, {required Color entityColor}) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r"(₹\s?[\d,]+(?:\.\d+)?)|'([^']+)'");
  int last = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start)));
    }
    final money = match.group(1);
    final quoted = match.group(2);
    if (money != null) {
      spans.add(TextSpan(
        text: money,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ));
    } else if (quoted != null) {
      spans.add(TextSpan(
        text: quoted,
        style: TextStyle(color: entityColor, fontWeight: FontWeight.w700),
      ));
    }
    last = match.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last)));
  }
  return spans;
}
