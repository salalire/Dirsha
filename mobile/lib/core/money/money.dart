/// Monetary value representation for Dirsha.
///
/// The backend represents all ETB amounts as **integer santim**
/// (minor units). 1 ETB = 100 santim.
///
/// Examples:
///   700000 santim  →  ETB 7,000.00
///   10000  santim  →  ETB 100.00
///   50     santim  →  ETB 0.50
///
/// Rules enforced by this class:
/// - The authoritative value is always stored as an integer [santim].
/// - Conversion to ETB (double) happens ONLY for display formatting.
/// - No floating-point arithmetic is ever performed on monetary values.
/// - fromJson accepts both integer santim (int) and the legacy string
///   format used in existing mock data, so the transition does not
///   break the currently tested UI.
///
/// DEPENDENCY ON MEMBER 2:
/// Field names containing santim amounts use the suffix `_minor` in the
/// confirmed contract, e.g. `available_minor`, `reserved_minor`,
/// `total_minor`, `price_per_share_minor`.
/// Update [WalletSummary.fromJson] and [IpoSummary.fromJson] field keys
/// once Member 2 finalises the exact JSON keys.
library;

/// An immutable monetary amount stored as integer santim (minor units).
///
/// 1 ETB = 100 santim.
class Money {
  const Money(this.santim) : assert(santim >= 0, 'santim must be non-negative');

  /// Zero ETB.
  static const Money zero = Money(0);

  /// The authoritative value — never use this for display directly.
  final int santim;

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parses a JSON value into [Money].
  ///
  /// Accepts:
  /// - `int`    → treated as santim (the confirmed backend contract).
  /// - `String` → parsed as santim integer if it contains no decimal point,
  ///              or as an ETB decimal string (legacy mock format e.g. "7000.00")
  ///              and converted to santim by multiplying by 100.
  ///
  /// Falls back to [Money.zero] if the value is null or cannot be parsed,
  /// rather than crashing, so missing optional fields degrade gracefully.
  factory Money.fromJson(dynamic value) {
    if (value == null) return Money.zero;

    if (value is int) {
      return Money(value);
    }

    if (value is double) {
      // Should not appear in the backend contract, but handle defensively.
      // Multiply by 100 and round to nearest santim.
      return Money((value * 100).round());
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return Money.zero;

      // Integer string — treat as santim (real API format).
      if (!trimmed.contains('.')) {
        final parsed = int.tryParse(trimmed);
        if (parsed != null && parsed >= 0) return Money(parsed);
        return Money.zero;
      }

      // Decimal string — legacy mock format "7000.00" treated as ETB,
      // converted to santim by multiplying by 100.
      final parsed = double.tryParse(trimmed);
      if (parsed != null && parsed >= 0) return Money((parsed * 100).round());
      return Money.zero;
    }

    return Money.zero;
  }

  // ---------------------------------------------------------------------------
  // Display
  // ---------------------------------------------------------------------------

  /// ETB value as a double — for display formatting ONLY.
  /// Never use this for calculations or comparisons.
  double get etb => santim / 100.0;

  /// Serializes back to santim integer for JSON requests.
  int toJson() => santim;

  // ---------------------------------------------------------------------------
  // Comparison and equality
  // ---------------------------------------------------------------------------

  bool operator >(Money other) => santim > other.santim;
  bool operator >=(Money other) => santim >= other.santim;
  bool operator <(Money other) => santim < other.santim;
  bool operator <=(Money other) => santim <= other.santim;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.santim == santim);

  @override
  int get hashCode => santim.hashCode;

  @override
  String toString() => 'Money($santim santim)';
}
