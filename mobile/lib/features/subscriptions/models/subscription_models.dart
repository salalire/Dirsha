import 'package:flutter/foundation.dart';

enum SubscriptionStatus {
  reserved,
  allocated,
  partiallyAllocated,
  released,
  cancelled,
  unknown;

  static SubscriptionStatus fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'reserved':
        return SubscriptionStatus.reserved;
      case 'allocated':
        return SubscriptionStatus.allocated;
      case 'partially_allocated':
        return SubscriptionStatus.partiallyAllocated;
      case 'released':
        return SubscriptionStatus.released;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionStatus.reserved:
        return 'Reserved';
      case SubscriptionStatus.allocated:
        return 'Allocated';
      case SubscriptionStatus.partiallyAllocated:
        return 'Partially Allocated';
      case SubscriptionStatus.released:
        return 'Released';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.unknown:
        return 'Unknown';
    }
  }
}

@immutable
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.ipoId,
    required this.investorId,
    required this.quantity,
    required this.amountMinor,
    required this.allocatedQuantity,
    required this.status,
    this.reservationLedgerEntryId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ipoId;
  final String investorId;
  final int quantity;
  final int amountMinor;
  final int allocatedQuantity;
  final SubscriptionStatus status;
  final String? reservationLedgerEntryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get amountEtb => amountMinor / 100.0;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      ipoId: (json['ipo_id'] ?? json['ipoId']) as String,
      investorId: (json['investor_id'] ?? json['investorId']) as String,
      quantity: (json['quantity'] as num).toInt(),
      amountMinor:
          ((json['amount_minor'] ?? json['amountMinor']) as num).toInt(),
      allocatedQuantity:
          ((json['allocated_quantity'] ?? json['allocatedQuantity'] ?? 0)
                  as num)
              .toInt(),
      status: SubscriptionStatus.fromString(json['status'] as String?),
      reservationLedgerEntryId: (json['reservation_ledger_entry_id'] ??
          json['reservationLedgerEntryId']) as String?,
      createdAt:
          DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
      updatedAt:
          DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String),
    );
  }
}
