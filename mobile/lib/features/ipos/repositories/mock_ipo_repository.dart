import '../models/ipo_models.dart';
import 'ipo_repository.dart';

/// Development mock for [IpoRepository].
///
/// IMPORTANT: This is NOT connected to the backend. All data is
/// fabricated for UI development only. It must not be used in production.
///
/// The [MockDataBanner] is displayed on all screens using this repository
/// so mock data is never mistaken for real offering information.
///
/// Mock IPOs use clearly fictional company names (Dev Corp A, Dev Corp B)
/// so they cannot be confused with real Ethiopian companies or real
/// investment opportunities.
class MockIpoRepository implements IpoRepository {
  static const _delay = Duration(milliseconds: 700);

  static final _items = <IpoSummary>[
    IpoSummary(
      id: 'mock-ipo-001',
      title: 'Dev Corp A — Series A Offering',
      companyName: 'Dev Corp A [MOCK]',
      status: 'OPEN',
      pricePerShare: '100.00',
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 10, 1),
      subscriptionEndDate: DateTime(2026, 11, 30),
      totalShares: 1000000,
      availableShares: 650000,
      minInvestment: '1000.00',
      maxInvestment: '500000.00',
      shortDescription:
          'A fictional company used for Phase 1 development testing. '
          'This is not a real investment opportunity.',
    ),
    IpoSummary(
      id: 'mock-ipo-002',
      title: 'Dev Corp B — Initial Public Offering',
      companyName: 'Dev Corp B [MOCK]',
      status: 'UPCOMING',
      pricePerShare: '50.00',
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 12, 1),
      subscriptionEndDate: DateTime(2027, 1, 31),
      totalShares: 500000,
      availableShares: 500000,
      minInvestment: '500.00',
      maxInvestment: '250000.00',
      shortDescription:
          'A fictional company used for Phase 1 development testing. '
          'This is not a real investment opportunity.',
    ),
    IpoSummary(
      id: 'mock-ipo-003',
      title: 'Dev Corp C — Closed Offering',
      companyName: 'Dev Corp C [MOCK]',
      status: 'CLOSED',
      pricePerShare: '200.00',
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 7, 1),
      subscriptionEndDate: DateTime(2026, 9, 30),
      totalShares: 200000,
      availableShares: 0,
      minInvestment: '2000.00',
      maxInvestment: '1000000.00',
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
      pricePerShare: '100.00',
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 10, 1),
      subscriptionEndDate: DateTime(2026, 11, 30),
      totalShares: 1000000,
      availableShares: 650000,
      minInvestment: '1000.00',
      maxInvestment: '500000.00',
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
      pricePerShare: '50.00',
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 12, 1),
      subscriptionEndDate: DateTime(2027, 1, 31),
      totalShares: 500000,
      availableShares: 500000,
      minInvestment: '500.00',
      maxInvestment: '250000.00',
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
      pricePerShare: '200.00',
      currency: 'ETB',
      subscriptionStartDate: DateTime(2026, 7, 1),
      subscriptionEndDate: DateTime(2026, 9, 30),
      totalShares: 200000,
      availableShares: 0,
      minInvestment: '2000.00',
      maxInvestment: '1000000.00',
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
    if (detail == null) {
      throw ArgumentError('Mock IPO not found: $id');
    }
    return detail;
  }
}
