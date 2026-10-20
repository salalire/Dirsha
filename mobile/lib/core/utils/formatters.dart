import 'package:intl/intl.dart';

/// Shared formatting utilities used across financial screens.
///
/// Financial values are formatted here for DISPLAY only.
/// Never use these functions for calculations or business logic.
abstract final class Formatters {
  static final _compact = NumberFormat.compact(locale: 'en');
  static final _dateShort = DateFormat('MMM d, yyyy');
  static final _dateMedium = DateFormat('MMMM d, yyyy');
  static final _dateTime = DateFormat('MMM d, yyyy • h:mm a');

  /// Formats a monetary string for display, e.g. "7000.00" → "ETB 7,000.00".
  ///
  /// Falls back to the raw string if parsing fails rather than crashing.
  static String currency(String amount, {String symbol = 'ETB'}) {
    final value = double.tryParse(amount);
    if (value == null) return '$symbol $amount';
    return NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
    ).format(value);
  }

  /// Compact number format, e.g. 1,200,000 → "1.2M".
  static String compact(num value) => _compact.format(value);

  /// Short date, e.g. "Oct 20, 2026".
  static String dateShort(DateTime date) => _dateShort.format(date);

  /// Medium date, e.g. "October 20, 2026".
  static String dateMedium(DateTime date) => _dateMedium.format(date);

  /// Date and time, e.g. "Oct 20, 2026 • 10:30 AM".
  static String dateTime(DateTime date) => _dateTime.format(date);

  /// Relative time label for transaction rows.
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return dateShort(date);
  }
}
