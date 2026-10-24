import '../models/portfolio_models.dart';
import 'portfolio_repository.dart';

class MockPortfolioRepository implements PortfolioRepository {
  PortfolioModel _portfolio = PortfolioModel(
    summary: PortfolioSummaryModel(
      totalPositions: 1,
      totalShares: 40,
      totalValuationMinor: 400000,
      currency: 'ETB',
      valuationSource: 'ipo_offering_price',
      asOf: DateTime.now(),
    ),
    holdings: [
      HoldingModel(
        ipoId: 'ipo-open-1',
        subscriptionId: 'sub-mock-001',
        companyId: 'comp-1',
        companyName: 'Ethio Telecom SC (TEST DATA)',
        symbol: 'ETHTEL',
        title: 'Ethio Telecom Public Offering (TEST DATA)',
        allocatedQuantity: 40,
        pricePerShareMinor: 10000,
        totalValueMinor: 400000,
        currency: 'ETB',
        valuationSource: 'ipo_offering_price',
        allocatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  );

  @override
  Future<PortfolioModel> getPortfolio() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _portfolio;
  }

  void setPortfolio(PortfolioModel p) {
    _portfolio = p;
  }
}
