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
  factory WalletSummary.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;
    return WalletSummary(
      id: (json['id'] as String?) ?? '',
      currency: json['currency'] as String? ?? 'ETB',
      available: Money.fromJson(
        json['available_minor'] ?? json['availableBalance'] ?? 0,
      ),
      reserved: Money.fromJson(
        json['reserved_minor'] ?? json['reservedBalance'] ?? 0,
      ),
      total: Money.fromJson(
        json['total_minor'] ??
            json['totalBalance'] ??
            ((json['available_minor'] is int && json['reserved_minor'] is int)
                ? (json['available_minor'] as int) +
                    (json['reserved_minor'] as int)
                : 0),
      ),
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

  factory WalletTransaction.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;
    final rawType = (json['type'] as String?) ?? 'test_fund_credit';
    final normalizedType = _normalizeType(rawType);
    final rawStatus = (json['status'] as String?) ?? 'posted';
    final normalizedStatus = _normalizeStatus(rawStatus);

    final deltaAvailable = (json['available_delta_minor'] as int?);
    final deltaReserved = (json['reserved_delta_minor'] as int?);
    int? resolvedMinor = json['amount_minor'] as int?;
    if (resolvedMinor == null && deltaAvailable != null) {
      resolvedMinor = deltaAvailable.abs();
    } else if (resolvedMinor == null && deltaReserved != null) {
      resolvedMinor = deltaReserved.abs();
    }

    final rawDate = json['created_at'] ?? json['createdAt'] ?? '';
    final createdAt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();

    return WalletTransaction(
      id: (json['id'] as String?) ?? '',
      type: normalizedType,
      status: normalizedStatus,
      amount: Money.fromJson(resolvedMinor ?? json['amount'] ?? 0),
      currency: json['currency'] as String? ?? 'ETB',
      createdAt: createdAt,
      description: json['description'] as String?,
      referenceId: (json['reference_id'] ?? json['referenceId']) as String?,
      referenceType:
          (json['reference_type'] ?? json['referenceType']) as String?,
    );
  }

  static String _normalizeType(String type) {
    switch (type.toLowerCase()) {
      case 'test_fund_credit':
      case 'credit':
        return 'CREDIT';
      case 'subscription_reserve':
      case 'reservation':
        return 'RESERVATION';
      case 'subscription_release':
      case 'release':
        return 'RELEASE';
      case 'subscription_settle':
      case 'settlement':
        return 'SETTLEMENT';
      case 'adjustment':
      case 'debit':
        return 'DEBIT';
      case 'refund':
        return 'REFUND';
      default:
        return type.toUpperCase();
    }
  }

  static String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
      case 'completed':
        return 'COMPLETED';
      case 'pending':
        return 'PENDING';
      case 'failed':
        return 'FAILED';
      case 'reversed':
        return 'REVERSED';
      default:
        return status.toUpperCase();
    }
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
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PaginatedTransactions(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(WalletTransaction.fromJson)
          .toList(),
      total: (pagination?['total'] ?? json['total']) as int? ?? rawItems.length,
      page: (pagination?['page'] ?? json['page']) as int? ?? 1,
      pageSize:
          (pagination?['page_size'] ??
                  pagination?['pageSize'] ??
                  json['pageSize']) as int? ??
              20,
    );
  }

  final List<WalletTransaction> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
}
