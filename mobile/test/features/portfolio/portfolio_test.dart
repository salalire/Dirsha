import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/portfolio/models/portfolio_models.dart';
import 'package:dirsha_mobile/features/portfolio/providers/portfolio_provider.dart';
import 'package:dirsha_mobile/features/portfolio/repositories/mock_portfolio_repository.dart';

void main() {
  group('Portfolio Models & Money calculations', () {
    test('HoldingModel computes market valuation and ETB conversions correctly', () {
      final holding = HoldingModel(
        ipoId: 'ipo-ethio-telecom-001',
        subscriptionId: 'sub-test-001',
        companyId: 'comp-ethio-telecom',
        title: 'Ethio Telecom Class A Shares',
        symbol: 'ETHTEL',
        companyName: 'Ethio Telecom SC',
        allocatedQuantity: 120,
        pricePerShareMinor: 30000,
        totalValueMinor: 3600000,
        currency: 'ETB',
        valuationSource: 'ipo_offering_price',
        allocatedAt: DateTime.parse('2026-03-20T10:00:00Z'),
      );

      expect(holding.totalValueMinor, 3600000); // 120 * 300.00 = 3,600.00 ETB
      expect(holding.totalValueEtb, 36000.0);
      expect(holding.pricePerShareEtb, 300.0);
      expect(holding.allocatedQuantity, 120);
    });

    test('PortfolioSummaryModel correctly reflects holdings count and total valuation', () {
      final summary = PortfolioSummaryModel(
        totalPositions: 1,
        totalShares: 120,
        totalValuationMinor: 3600000,
        currency: 'ETB',
        valuationSource: 'ipo_offering_price',
        asOf: DateTime.parse('2026-03-20T10:00:00Z'),
      );

      expect(summary.totalValuationMinor, 3600000);
      expect(summary.totalValuationEtb, 36000.0);
      expect(summary.totalPositions, 1);
      expect(summary.totalShares, 120);
      expect(summary.currency, 'ETB');
    });
  });

  group('PortfolioProvider', () {
    late MockPortfolioRepository repository;
    late PortfolioProvider provider;

    setUp(() {
      repository = MockPortfolioRepository();
      provider = PortfolioProvider(repository: repository);
    });

    test('initial state is idle without loaded data', () {
      expect(provider.isLoading, isFalse);
      expect(provider.portfolio, isNull);
      expect(provider.holdings, isEmpty);
      expect(provider.summary, isNull);
      expect(provider.error, isNull);
    });

    test('load() retrieves portfolio and updates holdings and summary', () async {
      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.portfolio, isNotNull);
      expect(provider.holdings.isNotEmpty, isTrue);
      expect(provider.summary, isNotNull);
      expect(provider.error, isNull);
      expect(provider.holdings.first.symbol, 'ETHTEL');
    });

    test('refresh() updates existing portfolio smoothly', () async {
      await provider.load();
      expect(provider.holdings.length, 1);

      await provider.refresh();
      expect(provider.holdings.length, 1);
      expect(provider.error, isNull);
    });
  });
}
