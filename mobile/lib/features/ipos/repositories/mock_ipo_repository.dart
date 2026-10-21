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
      title: 'Dev Corp A — Series A Offering',
      companyName: 'Dev Corp A [MOCK]',
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
          'A fictional company used for Phase 1 development testing. '
          'This is not a real investment opportunity.',
    ),
    IpoSummary(
      id: 'mock-ipo-002',
      title: 'Dev Corp B — Initial Public Offering',
      companyName: 'Dev Corp B [MOCK]',
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
          'A fictional company used for Phase 1 development testing. '
          'This is not a real investment opportunity.',
    ),
    IpoSummary(
      id: 'mock-ipo-003',
      title: 'Dev Corp C — Closed Offering',
      companyName: 'Dev Corp C [MOCK]',
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
          'A fictional company used for Phase 1 development testing. '
          'Subscription period has ended.',
    ),
  ];

  static final _details = <String, IpoDetail>{
    'mock-ipo-001': IpoDetail(
      id: 'mock-ipo-001',
      title: 'Dev Corp A — Series A Offering',
      companyName: 'Dev Corp A [MOCK]',
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
          'A fictional company used for Phase 1 development testing.',
      description:
          'Dev Corp A is a fictional entity created solely for mobile '
          'development and testing purposes during Dirsha Phase 1. '
          'It does not represent a real company, real securities, or a '
          'real investment opportunity. All figures shown are simulated '
          'test data.\n\n'
          'This offering is open for subscription in the development '
          'environment only.',
      companyDescription:
          'Dev Corp A [MOCK] — fictional test company. Not a real entity.',
      riskDisclosure:
          'DEVELOPMENT ENVIRONMENT ONLY. This is mock data. '
          'No real investment is possible through this interface in Phase 1. '
          'Do not make financial decisions based on this screen.',
      subscribedShares: 350000,
    ),
    'mock-ipo-002': IpoDetail(
      id: 'mock-ipo-002',
      title: 'Dev Corp B — Initial Public Offering',
      companyName: 'Dev Corp B [MOCK]',
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
          'A fictional company used for Phase 1 development testing.',
      description:
          'Dev Corp B is a fictional entity for development testing. '
          'Subscription has not yet opened.',
      companyDescription:
          'Dev Corp B [MOCK] — fictional test company. Not a real entity.',
      riskDisclosure: 'DEVELOPMENT ENVIRONMENT ONLY. This is mock data.',
    ),
    'mock-ipo-003': IpoDetail(
      id: 'mock-ipo-003',
      title: 'Dev Corp C — Closed Offering',
      companyName: 'Dev Corp C [MOCK]',
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
      description: 'Dev Corp C is a fictional closed offering for testing.',
      companyDescription:
          'Dev Corp C [MOCK] — fictional test company. Not a real entity.',
      riskDisclosure: 'DEVELOPMENT ENVIRONMENT ONLY. This is mock data.',
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
