import 'package:intl/intl.dart';

class Money {
  static final _inr0 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _inr2 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String formatCents(int cents) {
    final rupees = cents / 100;
    // Show decimals only when there's a fractional part
    if (cents % 100 == 0) {
      return _inr0.format(rupees.round());
    }
    return _inr2.format(rupees);
  }

  static int parseRupeesToCents(String input) {
    // Allow decimal values like "12.50" or "₹12.50"
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0;
    final value = double.tryParse(cleaned);
    if (value == null) return 0;
    return (value * 100).round();
  }
}
