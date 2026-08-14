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

/// Fixed IST offset (UTC+5:30) — matches the backend's IST scheduling
/// (see app/core/scheduler.py). Using a fixed offset instead of
/// DateTime.toLocal() means times always read as Indian time regardless
/// of the device's own timezone/locale setting.
const Duration _istOffset = Duration(hours: 5, minutes: 30);

/// Converts a UTC (or otherwise absolute) DateTime to IST wall-clock time.
DateTime toIst(DateTime dateTime) {
  return dateTime.toUtc().add(_istOffset);
}

/// "3:45 PM" — 12-hour clock, IST.
String formatIstTime(DateTime dateTime) {
  return DateFormat('h:mm a').format(toIst(dateTime));
}

/// "14 Aug 2026" — IST calendar date.
String formatIstDate(DateTime dateTime) {
  return DateFormat('d MMM yyyy').format(toIst(dateTime));
}

/// "14 Aug 2026, 3:45 PM" — full IST date + 12-hour time, for tournament
/// room-publish / auto-complete / schedule timestamps.
String formatIstDateTime(DateTime dateTime) {
  return '${formatIstDate(dateTime)}, ${formatIstTime(dateTime)}';
}

/// "2m ago" / "3h ago" style relative timestamp for recent items, falling
/// back to "Yesterday, 8:30 PM" / "12 Jun, 3:15 PM" for older ones — matches
/// the notification reference design's timestamp treatment. Always reads
/// in IST regardless of device timezone.
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now().toUtc();
  final diff = now.difference(dateTime.toUtc());

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';

  final nowIst = toIst(now);
  final thatIst = toIst(dateTime);
  final today = DateTime(nowIst.year, nowIst.month, nowIst.day);
  final that = DateTime(thatIst.year, thatIst.month, thatIst.day);
  final dayDiff = today.difference(that).inDays;
  final time = formatIstTime(dateTime);

  if (dayDiff == 1) return 'Yesterday, $time';
  if (dayDiff < 7) return '${DateFormat('EEEE').format(thatIst)}, $time';
  return '${DateFormat('d MMM').format(thatIst)}, $time';
}
