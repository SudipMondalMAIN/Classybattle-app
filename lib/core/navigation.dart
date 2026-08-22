import 'package:flutter/material.dart';

/// App-wide navigator key. Attached to [MaterialApp] in main.dart.
///
/// Needed because [PushNotificationHandler] reacts to FCM taps from
/// outside the widget tree (no [BuildContext] of its own) -- this lets
/// it push routes the same way an in-app notification tap does.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
