import 'package:intl/intl.dart';

import '../money/money.dart';

/// Shared formatting utilities used across financial screens.
///
/// Financial values are formatted here for DISPLAY only.
/// Never use these functions for calculations or business logic.
///
/// Monetary contract (confirmed by Member 2):
///   Backend amounts are integer santim. 1 ETB = 100 santim.
///   Use [Formatters.money] for all [Money] values.
///   The legacy [Formatters.currency] method is kept for backward
///   compatibility with string-based fields not yet migrated.
abstract final class Formatters {
  static final _compact = NumberFormat.compact(locale: 'en');
  static final _dateShort = DateFormat('MMM d, yyyy');
  static final _dateMedium = DateFormat('MMMM d, yyyy');
  static final _dateTime = DateFormat('MMM d, yyyy • h:mm a');

  // ---------------------------------------------------------------------------
  // Primary: Money → ETB display
  // ---------------------------------------------------------------------------

  /// Formats a [Money] value for display.
  ///
  /// Converts santim to ETB internally; never stores the double result.
  ///
  /// Example: Money(700000) → "ETB 7,000.00"
  static String money(Money amount, {String symbol = 'ETB'}) {
    return NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
    ).format(amount.etb);
  }

  // ---------------------------------------------------------------------------
  // Legacy: String → ETB display
  //
  // Kept for fields not yet migrated to Money (e.g. IPO monetary fields
  // that still use String in existing mock data).
  //
  // When the real API is connected and all fields use integer santim,
  // callers should migrate to Formatters.money().
  // ---------------------------------------------------------------------------

  /// Formats a string amount for display.
  ///
  /// If the string contains a decimal point it is treated as an ETB value
  /// (legacy mock format). If it is a plain integer it is treated as santim
  /// and converted to ETB first.
  ///
  /// Example (ETB string):   "7000.00"  → "ETB 7,000.00"
  /// Example (santim int str): "700000" → "ETB 7,000.00"
  static String currency(String amount, {String symbol = 'ETB'}) {
    final trimmed = amount.trim();
    if (trimmed.isEmpty) return '$symbol 0.00';

    double? value;
    if (trimmed.contains('.')) {
      // Legacy ETB decimal string
      value = double.tryParse(trimmed);
    } else {
      // Santim integer string — convert to ETB
      final santim = int.tryParse(trimmed);
      if (santim != null) value = santim / 100.0;
    }

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
