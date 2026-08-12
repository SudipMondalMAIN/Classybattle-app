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
