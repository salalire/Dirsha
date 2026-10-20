/// Wallet and ledger data models for Dirsha.
///
/// The backend is the sole authoritative source for balances and
/// transactions. The mobile app must never calculate or modify balances
/// independently.
///
/// DEPENDENCY ON MEMBER 2:
/// - Confirm monetary representation (string, integer minor units, or decimal).
/// - Confirm transaction type and status enum values.
/// - Confirm pagination envelope shape.
/// - Confirm whether GET /wallets/me or GET /wallets/:userId is used.
///
/// All amounts are stored as strings here to avoid floating-point
/// precision loss. Parse to double ONLY for display formatting.
library;

/// The investor's wallet summary — returned by GET /wallets/me.
class WalletSummary {
  const WalletSummary({
    required this.id,
    required this.currency,
    required this.availableBalance,
    required this.reservedBalance,
    required this.totalBalance,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      id: json['id'] as String,
      currency: json['currency'] as String? ?? 'ETB',
      availableBalance: json['availableBalance'].toString(),
      reservedBalance: json['reservedBalance'].toString(),
      totalBalance: json['totalBalance'].toString(),
    );
  }

  final String id;
  final String currency;

  /// Funds available for new subscriptions or operations.
  final String availableBalance;

  /// Funds currently reserved for pending subscriptions or orders.
  final String reservedBalance;

  /// Total balance = available + reserved. Displayed for reference only;
  /// the backend is authoritative for the actual value.
  final String totalBalance;

  /// Convenience: parses [availableBalance] for display.
  /// Never use this value for any financial calculation.
  double get availableBalanceDisplay =>
      double.tryParse(availableBalance) ?? 0.0;

  double get reservedBalanceDisplay => double.tryParse(reservedBalance) ?? 0.0;

  double get totalBalanceDisplay => double.tryParse(totalBalance) ?? 0.0;

  @override
  String toString() =>
      'WalletSummary(currency: $currency, available: $availableBalance, '
      'reserved: $reservedBalance)';
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
      amount: json['amount'].toString(),
      currency: json['currency'] as String? ?? 'ETB',
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
    );
  }

  final String id;

  /// Transaction type from the agreed enum:
  /// CREDIT | DEBIT | RESERVATION | RELEASE | REFUND | SETTLEMENT
  /// (pending confirmation from Member 2)
  final String type;

  /// Transaction status:
  /// PENDING | COMPLETED | FAILED | REVERSED
  final String status;

  /// Amount as a string — parse for display only.
  final String amount;
  final String currency;
  final DateTime createdAt;

  /// Human-readable description from the backend, e.g. "IPO subscription".
  final String? description;

  /// ID of the related business object (subscription ID, order ID, etc.).
  final String? referenceId;

  /// Type of the related object: "SUBSCRIPTION", "ORDER", "ALLOCATION", etc.
  final String? referenceType;

  /// True when this transaction reduces available balance.
  bool get isDebit =>
      type == 'DEBIT' || type == 'RESERVATION' || type == 'SETTLEMENT';

  /// True when this transaction increases available balance.
  bool get isCredit =>
      type == 'CREDIT' || type == 'RELEASE' || type == 'REFUND';

  double get amountDisplay => double.tryParse(amount) ?? 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'status': status,
    'amount': amount,
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
