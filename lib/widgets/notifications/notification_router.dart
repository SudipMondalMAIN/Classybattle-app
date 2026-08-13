import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../screens/settings_screen.dart';
import '../../screens/tournament_details_screen.dart';
import '../../screens/wallet_screen.dart';

/// Decides where a notification tap should navigate, based on real
/// backend event_type + meta_data — never text-matching the body.
void navigateForNotification(BuildContext context, NotificationModel n) {
  switch (n.eventType) {
    // Tournament-linked events: open the exact tournament if we have an id.
    case NotificationEventType.tournamentCreated:
    case NotificationEventType.tournamentUpdated:
    case NotificationEventType.tournamentCancelled:
    case NotificationEventType.registrationSuccessful:
    case NotificationEventType.registrationCancelled:
    case NotificationEventType.matchCreated:
    case NotificationEventType.matchStarted:
    case NotificationEventType.matchCompleted:
    case NotificationEventType.roomDetailsPublished:
    case NotificationEventType.liveMatchStarted:
    case NotificationEventType.matchResultApproved:
    case NotificationEventType.winnerDeclared:
      final id = n.tournamentId;
      if (id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournamentId: id)),
        );
      }
      return;

    // Wallet / transaction events: open Wallet.
    case NotificationEventType.walletCredited:
    case NotificationEventType.walletDebited:
    case NotificationEventType.refundCompleted:
    case NotificationEventType.prizeDistributed:
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
      return;

    // Account-related: send to Settings (profile/security lives there).
    case NotificationEventType.userRegistration:
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;

    // Broadcasts, system announcements, and anything unrecognised: no
    // valid destination — stay on Notifications (already marked read).
    case NotificationEventType.adminBroadcast:
    case NotificationEventType.systemAnnouncement:
    case NotificationEventType.general:
      return;
  }
}
