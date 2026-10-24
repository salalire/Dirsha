import 'package:flutter/foundation.dart';

@immutable
class HoldingModel {
  const HoldingModel({
    required this.ipoId,
    required this.subscriptionId,
    required this.companyId,
    required this.companyName,
    required this.symbol,
    required this.title,
    required this.allocatedQuantity,
    required this.pricePerShareMinor,
    required this.totalValueMinor,
    required this.currency,
    required this.valuationSource,
    required this.allocatedAt,
  });

  final String ipoId;
  final String subscriptionId;
  final String companyId;
  final String companyName;
  final String symbol;
  final String title;
  final int allocatedQuantity;
  final int pricePerShareMinor;
  final int totalValueMinor;
  final String currency;
  final String valuationSource;
  final DateTime allocatedAt;

  double get pricePerShareEtb => pricePerShareMinor / 100.0;
  double get totalValueEtb => totalValueMinor / 100.0;

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    return HoldingModel(
      ipoId: (json['ipo_id'] ?? json['ipoId']) as String,
      subscriptionId:
          (json['subscription_id'] ?? json['subscriptionId']) as String,
      companyId: (json['company_id'] ?? json['companyId']) as String,
      companyName:
          (json['company_name'] ?? json['companyName'] ?? '') as String,
      symbol: (json['symbol'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      allocatedQuantity:
          ((json['allocated_quantity'] ?? json['allocatedQuantity'] ?? 0)
                  as num)
              .toInt(),
      pricePerShareMinor: ((json['price_per_share_minor'] ??
              json['pricePerShareMinor'] ??
              0) as num)
          .toInt(),
      totalValueMinor:
          ((json['total_value_minor'] ?? json['totalValueMinor'] ?? 0) as num)
              .toInt(),
      currency: (json['currency'] ?? 'ETB') as String,
      valuationSource: (json['valuation_source'] ??
          json['valuationSource'] ??
          'ipo_offering_price') as String,
      allocatedAt: DateTime.parse(
          (json['allocated_at'] ?? json['allocatedAt']) as String),
    );
  }
}

@immutable
class PortfolioSummaryModel {
  const PortfolioSummaryModel({
    required this.totalPositions,
    required this.totalShares,
    required this.totalValuationMinor,
    required this.currency,
    required this.valuationSource,
    required this.asOf,
  });

  final int totalPositions;
  final int totalShares;
  final int totalValuationMinor;
  final String currency;
  final String valuationSource;
  final DateTime asOf;

  double get totalValuationEtb => totalValuationMinor / 100.0;

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) {
    return PortfolioSummaryModel(
      totalPositions:
          ((json['total_positions'] ?? json['totalPositions'] ?? 0) as num)
              .toInt(),
      totalShares:
          ((json['total_shares'] ?? json['totalShares'] ?? 0) as num).toInt(),
      totalValuationMinor: ((json['total_valuation_minor'] ??
              json['totalValuationMinor'] ??
              0) as num)
          .toInt(),
      currency: (json['currency'] ?? 'ETB') as String,
      valuationSource: (json['valuation_source'] ??
          json['valuationSource'] ??
          'ipo_offering_price') as String,
      asOf: DateTime.parse((json['as_of'] ??
          json['asOf'] ??
          DateTime.now().toIso8601String()) as String),
    );
  }

  static PortfolioSummaryModel empty() {
    return PortfolioSummaryModel(
      totalPositions: 0,
      totalShares: 0,
      totalValuationMinor: 0,
      currency: 'ETB',
      valuationSource: 'ipo_offering_price',
      asOf: DateTime.now(),
    );
  }
}

@immutable
class PortfolioModel {
  const PortfolioModel({
    required this.summary,
    required this.holdings,
  });

  final PortfolioSummaryModel summary;
  final List<HoldingModel> holdings;

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = (json['summary'] as Map<String, dynamic>?) ?? {};
    final holdingsRaw = (json['holdings'] as List<dynamic>?) ?? [];

    return PortfolioModel(
      summary: PortfolioSummaryModel.fromJson(summaryJson),
      holdings: holdingsRaw
          .map((h) => HoldingModel.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  static PortfolioModel empty() {
    return PortfolioModel(
      summary: PortfolioSummaryModel.empty(),
      holdings: const [],
    );
  }
}
