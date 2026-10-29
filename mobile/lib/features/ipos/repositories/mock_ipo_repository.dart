import 'package:dirsha_mobile/core/money/money.dart';
import '../models/ipo_models.dart';
import 'ipo_repository.dart';

/// Development mock for [IpoRepository].
///
/// IMPORTANT: Not connected to the backend. All data is fabricated for
/// UI development only. [MockDataBanner] is displayed on all screens.
///
/// Mock IPO companies are labeled [MOCK] — they are not real Ethiopian
/// companies and do not represent real investment opportunities.
///
/// Amounts use integer santim (1 ETB = 100 santim):
///   ETB 100.00  →  10_000 santim
///   ETB 50.00   →  5_000  santim
///   ETB 200.00  →  20_000 santim
///   ETB 1,000   →  100_000 santim  (minInvestment Dev Corp A)
///   ETB 500,000 →  50_000_000 santim (maxInvestment Dev Corp A)
class MockIpoRepository implements IpoRepository {
  static const _delay = Duration(milliseconds: 700);

  static final _items = <IpoSummary>[
    IpoSummary(
      id: 'mock-ipo-001',
      title: 'Ethio Telecom Enterprise — Series A Offering',
      companyName: 'Ethio Telecom Enterprise',
      status: 'OPEN',
      pricePerShare: Money(10000), // ETB 100.00
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 10, 1),
      subscriptionEndDate: DateTime(2026, 11, 30),
      totalShares: 1000000,
      availableShares: 650000,
      minInvestment: Money(100000), // ETB 1,000.00
      maxInvestment: Money(50000000), // ETB 500,000.00
      shortDescription:
          'Leading telecommunications provider expanding nationwide 5G infrastructure.',
    ),
    IpoSummary(
      id: 'mock-ipo-002',
      title: 'Abyssinia Logistics PLC — Initial Public Offering',
      companyName: 'Abyssinia Logistics PLC',
      status: 'UPCOMING',
      pricePerShare: Money(5000), // ETB 50.00
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 12, 1),
      subscriptionEndDate: DateTime(2027, 1, 31),
      totalShares: 500000,
      availableShares: 500000,
      minInvestment: Money(50000), // ETB 500.00
      maxInvestment: Money(25000000), // ETB 250,000.00
      shortDescription:
          'Integrated freight forwarder and cold-chain logistics operator.',
    ),
    IpoSummary(
      id: 'mock-ipo-003',
      title: 'Awash Agro Solutions — Public Offering',
      companyName: 'Awash Agro Solutions',
      status: 'CLOSED',
      pricePerShare: Money(20000), // ETB 200.00
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 7, 1),
      subscriptionEndDate: DateTime(2026, 9, 30),
      totalShares: 200000,
      availableShares: 0,
      minInvestment: Money(200000), // ETB 2,000.00
      maxInvestment: Money(100000000), // ETB 1,000,000.00
      shortDescription:
          'Specialty coffee and agro-processing export consortium.',
    ),
  ];

  static final _details = <String, IpoDetail>{
    'mock-ipo-001': IpoDetail(
      id: 'mock-ipo-001',
      title: 'Ethio Telecom Enterprise — Series A Offering',
      companyName: 'Ethio Telecom Enterprise',
      status: 'OPEN',
      pricePerShare: Money(10000),
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 10, 1),
      subscriptionEndDate: DateTime(2026, 11, 30),
      totalShares: 1000000,
      availableShares: 650000,
      minInvestment: Money(100000),
      maxInvestment: Money(50000000),
      shortDescription:
          'Leading telecommunications provider expanding nationwide 5G infrastructure.',
      description:
          'Ethio Telecom Enterprise is raising capital to accelerate fiber network deployment, expansion of mobile money infrastructure, and next-generation data center construction across the region.',
      companyDescription:
          'National telecommunications operator serving over 70 million subscribers with voice, broadband, and digital financial solutions.',
      riskDisclosure:
          'Investments in equity securities carry market risks. Past financial performance is not indicative of future results. Please refer to the full prospectus.',
      subscribedShares: 350000,
    ),
    'mock-ipo-002': IpoDetail(
      id: 'mock-ipo-002',
      title: 'Abyssinia Logistics PLC — Initial Public Offering',
      companyName: 'Abyssinia Logistics PLC',
      status: 'UPCOMING',
      pricePerShare: Money(5000),
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 12, 1),
      subscriptionEndDate: DateTime(2027, 1, 31),
      totalShares: 500000,
      availableShares: 500000,
      minInvestment: Money(50000),
      maxInvestment: Money(25000000),
      shortDescription:
          'Integrated freight forwarder and cold-chain logistics operator.',
      description:
          'Abyssinia Logistics operates modern warehousing and fleet services connecting key commercial corridors with international trade gateways.',
      companyDescription:
          'Logistics and supply chain management provider serving domestic and cross-border manufacturers.',
      riskDisclosure:
          'Investments in equities are subject to operational, supply chain, and regulatory risks.',
    ),
    'mock-ipo-003': IpoDetail(
      id: 'mock-ipo-003',
      title: 'Awash Agro Solutions — Public Offering',
      companyName: 'Awash Agro Solutions',
      status: 'CLOSED',
      pricePerShare: Money(20000),
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 7, 1),
      subscriptionEndDate: DateTime(2026, 9, 30),
      totalShares: 200000,
      availableShares: 0,
      minInvestment: Money(200000),
      maxInvestment: Money(100000000),
      shortDescription: 'Subscription period has ended.',
      description:
          'Awash Agro Solutions completed a successful offering to fund new export washing stations and storage silos.',
      companyDescription:
          'Premium agricultural processing company focusing on sustainable organic exports.',
      riskDisclosure:
          'Securities investments are subject to agricultural commodity price cycles.',
      subscribedShares: 200000,
      allocatedShares: 200000,
    ),
  };

  @override
  Future<PaginatedIpos> getIpos({int page = 1, int pageSize = 20}) async {
    await Future.delayed(_delay);
    return PaginatedIpos(
      items: _items,
      total: _items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<IpoDetail> getIpoById(String id) async {
    await Future.delayed(_delay);
    final detail = _details[id];
    if (detail == null) throw ArgumentError('Mock IPO not found: $id');
    return detail;
  }
}
