import 'package:flutter/foundation.dart';

@immutable
class TradableSecurity {
  const TradableSecurity({
    required this.ipoId,
    required this.symbol,
    required this.companyName,
    required this.status,
    required this.pricePerShareMinor,
    this.lastTradedPriceMinor,
    required this.totalTrades,
    required this.openOrdersCount,
  });

  final String ipoId;
  final String symbol;
  final String companyName;
  final String status;
  final int pricePerShareMinor;
  final int? lastTradedPriceMinor;
  final int totalTrades;
  final int openOrdersCount;

  double get pricePerShareEtb => pricePerShareMinor / 100.0;
  double get referencePriceEtb =>
      (lastTradedPriceMinor ?? pricePerShareMinor) / 100.0;

  factory TradableSecurity.fromJson(Map<String, dynamic> json) {
    return TradableSecurity(
      ipoId: (json['ipo_id'] ?? json['ipoId'] ?? '') as String,
      symbol: (json['symbol'] ?? '') as String,
      companyName:
          (json['company_name'] ?? json['companyName'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      pricePerShareMinor: ((json['price_per_share_minor'] ??
              json['pricePerShareMinor'] ??
              0) as num)
          .toInt(),
      lastTradedPriceMinor: json['last_traded_price_minor'] != null
          ? (json['last_traded_price_minor'] as num).toInt()
          : (json['lastTradedPriceMinor'] != null
              ? (json['lastTradedPriceMinor'] as num).toInt()
              : null),
      totalTrades: ((json['total_trades'] ?? json['totalTrades'] ?? 0) as num).toInt(),
      openOrdersCount:
          ((json['open_orders_count'] ?? json['openOrdersCount'] ?? 0) as num).toInt(),
    );
  }
}

@immutable
class ShareHolding {
  const ShareHolding({
    required this.id,
    required this.investorId,
    required this.ipoId,
    required this.quantity,
    required this.reservedQuantity,
    required this.symbol,
    required this.companyName,
    required this.pricePerShareMinor,
    this.lastTradedPriceMinor,
  });

  final String id;
  final String investorId;
  final String ipoId;
  final int quantity;
  final int reservedQuantity;
  final String symbol;
  final String companyName;
  final int pricePerShareMinor;
  final int? lastTradedPriceMinor;

  int get availableQuantity => quantity - reservedQuantity;
  double get pricePerShareEtb => pricePerShareMinor / 100.0;
  double get valuationEtb =>
      (quantity * (lastTradedPriceMinor ?? pricePerShareMinor)) / 100.0;

  factory ShareHolding.fromJson(Map<String, dynamic> json) {
    return ShareHolding(
      id: (json['id'] ?? '') as String,
      investorId: (json['investor_id'] ?? json['investorId'] ?? '') as String,
      ipoId: (json['ipo_id'] ?? json['ipoId'] ?? '') as String,
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      reservedQuantity:
          ((json['reserved_quantity'] ?? json['reservedQuantity'] ?? 0) as num)
              .toInt(),
      symbol: (json['symbol'] ?? '') as String,
      companyName:
          (json['company_name'] ?? json['companyName'] ?? '') as String,
      pricePerShareMinor: ((json['price_per_share_minor'] ??
              json['pricePerShareMinor'] ??
              0) as num)
          .toInt(),
      lastTradedPriceMinor: json['last_traded_price_minor'] != null
          ? (json['last_traded_price_minor'] as num).toInt()
          : (json['lastTradedPriceMinor'] != null
              ? (json['lastTradedPriceMinor'] as num).toInt()
              : null),
    );
  }
}

@immutable
class TradeOrder {
  const TradeOrder({
    required this.id,
    required this.userId,
    this.assistedByBrokerId,
    required this.ipoId,
    required this.symbol,
    required this.companyName,
    required this.side,
    required this.orderType,
    required this.pricePerShareMinor,
    required this.quantity,
    required this.filledQuantity,
    required this.status,
    required this.reservedAmountMinor,
    required this.isSimulated,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? assistedByBrokerId;
  final String ipoId;
  final String symbol;
  final String companyName;
  final String side; // 'buy' | 'sell'
  final String orderType; // 'limit' | 'market'
  final int pricePerShareMinor;
  final int quantity;
  final int filledQuantity;
  final String status; // 'open' | 'partially_filled' | 'filled' | 'cancelled' | 'rejected'
  final int reservedAmountMinor;
  final bool isSimulated;
  final DateTime createdAt;

  bool get isCancellable => status == 'open' || status == 'partially_filled';
  double get pricePerShareEtb => pricePerShareMinor / 100.0;
  double get totalAmountEtb => (quantity * pricePerShareMinor) / 100.0;
  int get remainingQuantity => quantity - filledQuantity;

  factory TradeOrder.fromJson(Map<String, dynamic> json) {
    return TradeOrder(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      assistedByBrokerId:
          (json['assisted_by_broker_id'] ?? json['assistedByBrokerId']) as String?,
      ipoId: (json['ipo_id'] ?? json['ipoId'] ?? '') as String,
      symbol: (json['symbol'] ?? '') as String,
      companyName:
          (json['company_name'] ?? json['companyName'] ?? '') as String,
      side: (json['side'] ?? 'buy') as String,
      orderType: (json['order_type'] ?? json['orderType'] ?? 'limit') as String,
      pricePerShareMinor: ((json['price_per_share_minor'] ??
              json['pricePerShareMinor'] ??
              0) as num)
          .toInt(),
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      filledQuantity:
          ((json['filled_quantity'] ?? json['filledQuantity'] ?? 0) as num)
              .toInt(),
      status: (json['status'] ?? 'open') as String,
      reservedAmountMinor: ((json['reserved_amount_minor'] ??
              json['reservedAmountMinor'] ??
              0) as num)
          .toInt(),
      isSimulated: (json['is_simulated'] ?? json['isSimulated'] ?? true) as bool,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? json['createdAt'] ?? '') as String) ??
          DateTime.now(),
    );
  }
}

@immutable
class TradeExecution {
  const TradeExecution({
    required this.id,
    required this.ipoId,
    required this.symbol,
    required this.companyName,
    required this.side,
    required this.pricePerShareMinor,
    required this.quantity,
    required this.totalAmountMinor,
    required this.isSimulated,
    required this.executedAt,
  });

  final String id;
  final String ipoId;
  final String symbol;
  final String companyName;
  final String side;
  final int pricePerShareMinor;
  final int quantity;
  final int totalAmountMinor;
  final bool isSimulated;
  final DateTime executedAt;

  double get pricePerShareEtb => pricePerShareMinor / 100.0;
  double get totalAmountEtb => totalAmountMinor / 100.0;

  factory TradeExecution.fromJson(Map<String, dynamic> json) {
    return TradeExecution(
      id: (json['id'] ?? '') as String,
      ipoId: (json['ipo_id'] ?? json['ipoId'] ?? '') as String,
      symbol: (json['symbol'] ?? '') as String,
      companyName:
          (json['company_name'] ?? json['companyName'] ?? '') as String,
      side: (json['side'] ?? '') as String,
      pricePerShareMinor: ((json['price_per_share_minor'] ??
              json['pricePerShareMinor'] ??
              0) as num)
          .toInt(),
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      totalAmountMinor:
          ((json['total_amount_minor'] ?? json['totalAmountMinor'] ?? 0) as num)
              .toInt(),
      isSimulated: (json['is_simulated'] ?? json['isSimulated'] ?? true) as bool,
      executedAt: DateTime.tryParse(
              (json['executed_at'] ?? json['executedAt'] ?? '') as String) ??
          DateTime.now(),
    );
  }
}

@immutable
class PlaceOrderResult {
  const PlaceOrderResult({
    required this.order,
    this.executions = const [],
  });

  final TradeOrder order;
  final List<TradeExecution> executions;

  factory PlaceOrderResult.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'] as Map<String, dynamic>;
    final executionsJson =
        (json['executions'] as List<dynamic>?) ?? const [];
    return PlaceOrderResult(
      order: TradeOrder.fromJson(orderJson),
      executions: executionsJson
          .map((e) => TradeExecution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
