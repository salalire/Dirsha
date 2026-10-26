import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dirsha_mobile/features/trading/models/trading_models.dart';
import 'package:dirsha_mobile/features/trading/providers/trading_provider.dart';
import 'package:dirsha_mobile/features/trading/repositories/mock_trading_repository.dart';
import 'package:dirsha_mobile/features/trading/screens/trading_screen.dart';
import 'package:dirsha_mobile/features/wallet/providers/wallet_provider.dart';
import 'package:dirsha_mobile/features/wallet/repositories/mock_wallet_repository.dart';

void main() {
  group('Trading Models & Calculations', () {
    test('TradableSecurity computes reference price in ETB correctly', () {
      const secWithLast = TradableSecurity(
        ipoId: 'sec-1',
        symbol: 'ETEL',
        companyName: 'Ethio Telecom S.C.',
        status: 'listed',
        pricePerShareMinor: 10000,
        lastTradedPriceMinor: 10550,
        totalTrades: 12,
        openOrdersCount: 4,
      );

      expect(secWithLast.pricePerShareEtb, 100.0);
      expect(secWithLast.referencePriceEtb, 105.50);

      const secNoLast = TradableSecurity(
        ipoId: 'sec-2',
        symbol: 'HBBR',
        companyName: 'Habesha Breweries S.C.',
        status: 'listed',
        pricePerShareMinor: 5000,
        lastTradedPriceMinor: null,
        totalTrades: 0,
        openOrdersCount: 1,
      );

      expect(secNoLast.referencePriceEtb, 50.0);
    });

    test('ShareHolding computes available quantity and market valuation correctly', () {
      const holding = ShareHolding(
        id: 'h-1',
        investorId: 'inv-1',
        ipoId: 'sec-1',
        quantity: 150,
        reservedQuantity: 50,
        symbol: 'ETEL',
        companyName: 'Ethio Telecom S.C.',
        pricePerShareMinor: 10000,
        lastTradedPriceMinor: 11000,
      );

      expect(holding.quantity, 150);
      expect(holding.reservedQuantity, 50);
      expect(holding.availableQuantity, 100);
      expect(holding.valuationEtb, 16500.0); // 150 * 110.00
    });

    test('TradeOrder isCancellable returns true only for open or partially_filled', () {
      final openOrder = TradeOrder(
        id: 'ord-1',
        userId: 'u-1',
        ipoId: 'sec-1',
        symbol: 'ETEL',
        companyName: 'Ethio Telecom',
        side: 'buy',
        orderType: 'limit',
        pricePerShareMinor: 10000,
        quantity: 10,
        filledQuantity: 0,
        status: 'open',
        reservedAmountMinor: 100000,
        isSimulated: true,
        createdAt: DateTime.now(),
      );
      expect(openOrder.isCancellable, isTrue);

      final filledOrder = TradeOrder(
        id: 'ord-2',
        userId: 'u-1',
        ipoId: 'sec-1',
        symbol: 'ETEL',
        companyName: 'Ethio Telecom',
        side: 'buy',
        orderType: 'limit',
        pricePerShareMinor: 10000,
        quantity: 10,
        filledQuantity: 10,
        status: 'filled',
        reservedAmountMinor: 0,
        isSimulated: true,
        createdAt: DateTime.now(),
      );
      expect(filledOrder.isCancellable, isFalse);
    });
  });

  group('TradingProvider', () {
    late MockTradingRepository repository;
    late TradingProvider provider;

    setUp(() {
      repository = MockTradingRepository();
      provider = TradingProvider(repository: repository);
    });

    test('loads securities, holdings, orders, and trades', () async {
      expect(provider.isLoading, isFalse);
      expect(provider.securities, isEmpty);

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.securities, isNotEmpty);
      expect(provider.securities.first.symbol, 'ETEL');
      expect(provider.holdings, isNotEmpty);
      expect(provider.orders, isNotEmpty);
      expect(provider.trades, isNotEmpty);
      expect(provider.error, isNull);
    });

    test('places simulated limit order and cancels it', () async {
      await provider.load();
      final initialCount = provider.orders.length;

      final result = await provider.placeOrder(
        ipoId: 'mock-ipo-1',
        side: 'buy',
        quantity: 5,
        pricePerShareMinor: 10000,
      );

      expect(result, isNotNull);
      expect(result!.order.quantity, 5);
      expect(provider.orders.length, initialCount + 1);

      // Cancel the order
      final ok = await provider.cancelOrder(result.order.id);
      expect(ok, isTrue);
      final cancelled = provider.orders.firstWhere((o) => o.id == result.order.id);
      expect(cancelled.status, 'cancelled');
    });
  });

  group('TradingScreen Widget', () {
    testWidgets('renders Secondary Trading screen with tabs and securities', (tester) async {
      final tradingRepo = MockTradingRepository();
      final tradingProvider = TradingProvider(repository: tradingRepo);
      final walletRepo = MockWalletRepository();
      final walletProvider = WalletProvider(repository: walletRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TradingProvider>.value(value: tradingProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ],
          child: const MaterialApp(
            home: TradingScreen(),
          ),
        ),
      );

      // Initial pump
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Secondary Trading'), findsOneWidget);
      expect(find.text('Securities'), findsOneWidget);
      expect(find.text('Holdings'), findsOneWidget);
      expect(find.text('Orders & Trades'), findsOneWidget);
      expect(find.text('ETEL'), findsOneWidget);
      expect(find.text('Ethio Telecom S.C.'), findsOneWidget);
      expect(find.text('Buy Shares'), findsWidgets);
      expect(find.text('Sell Shares'), findsWidgets);
    });
  });
}
