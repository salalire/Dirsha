/// Wallet and ledger data models for Dirsha.
///
/// Monetary contract (confirmed by Member 2):
///   All balance and transaction amounts are integer santim (minor units).
///   1 ETB = 100 santim.
///   Example: available_minor = 700000 means ETB 7,000.00
///
/// [Money] stores santim as int. Use [Formatters.money] for display.
/// Never parse santim to double for any purpose other than display.
///
/// DEPENDENCY ON MEMBER 2:
///   - Confirm exact JSON field names (e.g. available_minor vs availableMinor).
///   - Confirm transaction type and status enum values.
///   - Confirm pagination envelope shape.
///   - Confirm endpoint path: GET /wallets/me or GET /wallets/:userId.
library;

import 'package:dirsha_mobile/core/money/money.dart';

/// The investor's wallet summary — returned by GET /wallets/me.
class WalletSummary {
  const WalletSummary({
    required this.id,
    required this.currency,
    required this.available,
    required this.reserved,
    required this.total,
  });

  /// Parses wallet summary from the backend JSON response.
  ///
  /// Accepts the confirmed santim integer field names.
  /// Also accepts the legacy camelCase string names used in mock data
  /// so the currently tested UI continues to work without changes.
  ///
  /// Field name priority (first match wins):
  ///   available_minor > availableBalance  (santim int preferred)
  ///   reserved_minor  > reservedBalance
  ///   total_minor     > totalBalance
  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      id: json['id'] as String,
      currency: json['currency'] as String? ?? 'ETB',
      available: Money.fromJson(
        json['available_minor'] ?? json['availableBalance'],
      ),
      reserved: Money.fromJson(
        json['reserved_minor'] ?? json['reservedBalance'],
      ),
      total: Money.fromJson(json['total_minor'] ?? json['totalBalance']),
    );
  }

  final String id;
  final String currency;

  /// Funds available for new subscriptions or operations.
  final Money available;

  /// Funds currently reserved for pending subscriptions or orders.
  final Money reserved;

  /// Total balance (authoritative value from backend).
  final Money total;

  @override
  String toString() =>
      'WalletSummary(currency: $currency, '
      'available: ${available.santim} santim, '
      'reserved: ${reserved.santim} santim)';
}

/// A single ledger entry / transaction returned by GET /wallets/me/transactions.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.description,
    this.referenceId,
    this.referenceType,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      // Accepts amount_minor (santim int) or legacy amount (string/decimal).
      amount: Money.fromJson(json['amount_minor'] ?? json['amount']),
      currency: json['currency'] as String? ?? 'ETB',
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
    );
  }

  final String id;

  /// Transaction type — confirmed values pending Member 2:
  /// CREDIT | DEBIT | RESERVATION | RELEASE | REFUND | SETTLEMENT
  final String type;

  /// Transaction status — confirmed values pending Member 2:
  /// PENDING | COMPLETED | FAILED | REVERSED
  final String status;

  /// Amount in santim. Use [Formatters.money] for display.
  final Money amount;

  final String currency;
  final DateTime createdAt;

  /// Human-readable description from the backend.
  final String? description;

  /// ID of the related business object.
  final String? referenceId;

  /// Type of the related object: SUBSCRIPTION, ORDER, ALLOCATION, etc.
  final String? referenceType;

  /// True when this transaction reduces available balance.
  bool get isDebit =>
      type == 'DEBIT' || type == 'RESERVATION' || type == 'SETTLEMENT';

  /// True when this transaction increases available balance.
  bool get isCredit =>
      type == 'CREDIT' || type == 'RELEASE' || type == 'REFUND';

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'status': status,
    'amount_minor': amount.santim,
    'currency': currency,
    'createdAt': createdAt.toIso8601String(),
    'description': description,
    'referenceId': referenceId,
    'referenceType': referenceType,
  };
}

/// Paginated transaction history response.
class PaginatedTransactions {
  const PaginatedTransactions({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedTransactions.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? json['data'] as List? ?? [];
    return PaginatedTransactions(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(WalletTransaction.fromJson)
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  final List<WalletTransaction> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
}
