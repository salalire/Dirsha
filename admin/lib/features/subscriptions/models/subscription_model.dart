import 'package:flutter/foundation.dart';

enum AdminSubscriptionStatus {
  reserved,
  settled,
  cancelled,
  refunded,
}

extension AdminSubscriptionStatusLabel on AdminSubscriptionStatus {
  String get label {
    switch (this) {
      case AdminSubscriptionStatus.reserved:
        return 'Reserved';
      case AdminSubscriptionStatus.settled:
        return 'Settled';
      case AdminSubscriptionStatus.cancelled:
        return 'Cancelled';
      case AdminSubscriptionStatus.refunded:
        return 'Refunded';
    }
  }
}

@immutable
class AdminSubscription {
  const AdminSubscription({
    required this.id,
    required this.ipoId,
    required this.offeringTitle,
    required this.symbol,
    required this.companyName,
    required this.investorId,
    required this.investorName,
    required this.investorEmail,
    required this.quantity,
    required this.sharePriceMinor,
    required this.totalAmountMinor,
    required this.allocatedQuantity,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    this.allocatedAt,
  });

  final String id;
  final String ipoId;
  final String offeringTitle;
  final String symbol;
  final String companyName;
  final String investorId;
  final String investorName;
  final String investorEmail;
  final int quantity;
  final int sharePriceMinor;
  final int totalAmountMinor;
  final int allocatedQuantity;
  final AdminSubscriptionStatus status;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime? allocatedAt;

  double get sharePriceEtb => sharePriceMinor / 100.0;
  double get totalAmountEtb => totalAmountMinor / 100.0;

  int get effectivePricePerShareMinor {
    if (sharePriceMinor > 0) return sharePriceMinor;
    if (quantity > 0) return (totalAmountMinor / quantity).round();
    return 0;
  }

  int get allocatedAmountMinor => allocatedQuantity * effectivePricePerShareMinor;
  double get allocatedAmountEtb => allocatedAmountMinor / 100.0;

  int get unallocatedQuantity {
    final diff = quantity - allocatedQuantity;
    return diff > 0 ? diff : 0;
  }

  int get unallocatedRefundMinor => unallocatedQuantity * effectivePricePerShareMinor;
  double get unallocatedRefundEtb => unallocatedRefundMinor / 100.0;

  bool get isSettled => status == AdminSubscriptionStatus.settled;
  bool get isReserved => status == AdminSubscriptionStatus.reserved;
  bool get isPartial => isSettled && allocatedQuantity > 0 && allocatedQuantity < quantity;
  bool get isFull => isSettled && allocatedQuantity >= quantity;
  bool get isZero => isSettled && allocatedQuantity == 0;

  factory AdminSubscription.fromJson(Map<String, dynamic> json) {
    AdminSubscriptionStatus parsedStatus;
    final rawStatus = (json['status'] as String? ?? 'reserved').toLowerCase();
    switch (rawStatus) {
      case 'settled':
      case 'allocated':
      case 'partially_allocated':
        parsedStatus = AdminSubscriptionStatus.settled;
        break;
      case 'cancelled':
        parsedStatus = AdminSubscriptionStatus.cancelled;
        break;
      case 'refunded':
      case 'released':
        parsedStatus = AdminSubscriptionStatus.refunded;
        break;
      case 'reserved':
      default:
        parsedStatus = AdminSubscriptionStatus.reserved;
        break;
    }

    return AdminSubscription(
      id: json['id'] as String,
      ipoId: (json['ipo_id'] ?? json['ipoId'] ?? '') as String,
      offeringTitle: (json['ipo_title'] ?? json['offeringTitle'] ?? json['offering_title'] ?? 'IPO Offering') as String,
      symbol: (json['ipo_symbol'] ?? json['symbol'] ?? '') as String,
      companyName: (json['company_name'] ?? json['companyName'] ?? '') as String,
      investorId: (json['investor_id'] ?? json['investorId'] ?? '') as String,
      investorName: (json['investor_name'] ?? json['investorName'] ?? 'Investor') as String,
      investorEmail: (json['investor_email'] ?? json['investorEmail'] ?? '') as String,
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      sharePriceMinor: ((json['price_per_share_minor'] ?? json['sharePriceMinor'] ?? 0) as num).toInt(),
      totalAmountMinor: ((json['total_amount_minor'] ?? json['totalAmountMinor'] ?? 0) as num).toInt(),
      allocatedQuantity: ((json['allocated_quantity'] ?? json['allocatedQuantity'] ?? 0) as num).toInt(),
      status: parsedStatus,
      idempotencyKey: (json['idempotency_key'] ?? json['idempotencyKey'] ?? '') as String,
      createdAt: DateTime.parse((json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()) as String),
      allocatedAt: json['allocated_at'] != null ? DateTime.tryParse(json['allocated_at'] as String) : null,
    );
  }
}
