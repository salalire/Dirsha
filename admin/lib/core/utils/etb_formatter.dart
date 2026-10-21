/// Ethiopian Birr (ETB) currency formatting utilities.
///
/// IMPORTANT — Unit convention agreed with Member 2 (backend):
/// All monetary amounts are stored and transmitted as INTEGER MINOR UNITS
/// (santim), where 100 santim = 1 ETB.
///
/// Example: 1 500 ETB is represented as 150 000 (santim).
///
/// Rules:
/// - Never use floating-point arithmetic for financial calculations.
/// - Always receive and store amounts as int (santim).
/// - Only convert to a decimal string at the display layer, using this class.
/// - Never send a display-layer string back to the backend as a financial value.
///
/// Backend field naming convention (pending confirmation from Member 2):
/// Fields ending in _santim or _minor_units contain santim values.
/// Fields named pricePerShareSantim, totalAmountSantim, etc. use this unit.
abstract final class EtbFormatter {
  /// Formats an integer santim amount as a human-readable ETB string.
  ///
  /// Examples:
  ///   formatSantim(150000)  → "ETB 1,500.00"
  ///   formatSantim(50)      → "ETB 0.50"
  ///   formatSantim(0)       → "ETB 0.00"
  ///
  /// Uses integer arithmetic only. No floating-point involved.
  static String formatSantim(int santim) {
    // Integer arithmetic: avoid any floating-point representation
    final bool negative = santim < 0;
    final int absSantim = negative ? -santim : santim;

    final int wholeBirr = absSantim ~/ 100;      // integer division
    final int remainderSantim = absSantim % 100; // modulo

    final String wholeStr = _addThousandSeparators(wholeBirr);
    final String centsStr = remainderSantim.toString().padLeft(2, '0');

    return '${negative ? '-' : ''}ETB $wholeStr.$centsStr';
  }

  /// Formats a nullable santim amount, returning a fallback string if null.
  ///
  /// Example:
  ///   formatSantimOrFallback(null)    → "— (not provided)"
  ///   formatSantimOrFallback(150000)  → "ETB 1,500.00"
  static String formatSantimOrFallback(
    int? santim, {
    String fallback = '— (not provided)',
  }) {
    if (santim == null) return fallback;
    return formatSantim(santim);
  }

  /// Formats santim as ETB with a short label, for compact display.
  ///
  /// Example:
  ///   formatSantimCompact(1500000) → "ETB 15,000.00"
  static String formatSantimCompact(int santim) => formatSantim(santim);

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _addThousandSeparators(int value) {
    final String raw = value.toString();
    if (raw.length <= 3) return raw;

    final StringBuffer result = StringBuffer();
    final int offset = raw.length % 3;

    for (int i = 0; i < raw.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) {
        result.write(',');
      }
      result.write(raw[i]);
    }
    return result.toString();
  }
}
