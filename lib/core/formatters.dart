import 'package:intl/intl.dart';

/// Indian-locale rupee formatter, no decimal places for round amounts
/// (matches how prize pools / wallet balances read in the reference
/// design, e.g. "₹ 1,250").
final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

String formatRupees(num amount) {
  return '₹ ${_inr.format(amount.round())}';
}

String formatCount(num amount) {
  return _inr.format(amount.round());
}

/// "2m ago" / "3h ago" style relative timestamp for recent items, falling
/// back to "Yesterday, 8:30 PM" / "12 Jun, 3:15 PM" for older ones — matches
/// the notification reference design's timestamp treatment.
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';

  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final dayDiff = today.difference(that).inDays;
  final time = DateFormat('h:mm a').format(dateTime);

  if (dayDiff == 1) return 'Yesterday, $time';
  if (dayDiff < 7) return '${DateFormat('EEEE').format(dateTime)}, $time';
  return '${DateFormat('d MMM').format(dateTime)}, $time';
}
