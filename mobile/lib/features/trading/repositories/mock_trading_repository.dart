import '../models/trading_models.dart';
import 'trading_repository.dart';

class MockTradingRepository implements TradingRepository {
  MockTradingRepository() {
    _securities = [
      const TradableSecurity(
        ipoId: 'mock-ipo-1',
        symbol: 'ETEL',
        companyName: 'Ethio Telecom S.C.',
        status: 'listed',
        pricePerShareMinor: 10000,
        lastTradedPriceMinor: 10250,
        totalTrades: 42,
        openOrdersCount: 6,
      ),
      const TradableSecurity(
        ipoId: 'mock-ipo-2',
        symbol: 'HBBR',
        companyName: 'Habesha Breweries S.C.',
        status: 'listed',
        pricePerShareMinor: 5000,
        lastTradedPriceMinor: 4950,
        totalTrades: 19,
        openOrdersCount: 3,
      ),
    ];

    _holdings = [
      const ShareHolding(
        id: 'mock-holding-1',
        investorId: 'mock-inv-1',
        ipoId: 'mock-ipo-1',
        quantity: 100,
        reservedQuantity: 0,
        symbol: 'ETEL',
        companyName: 'Ethio Telecom S.C.',
        pricePerShareMinor: 10000,
        lastTradedPriceMinor: 10250,
      ),
    ];

    _orders = [
      TradeOrder(
        id: 'mock-order-1',
        userId: 'mock-inv-1',
        ipoId: 'mock-ipo-1',
        symbol: 'ETEL',
        companyName: 'Ethio Telecom S.C.',
        side: 'buy',
        orderType: 'limit',
        pricePerShareMinor: 10000,
        quantity: 20,
        filledQuantity: 0,
        status: 'open',
        reservedAmountMinor: 200000,
        isSimulated: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    _trades = [
      TradeExecution(
        id: 'mock-trade-1',
        ipoId: 'mock-ipo-1',
        symbol: 'ETEL',
        companyName: 'Ethio Telecom S.C.',
        side: 'buy',
        pricePerShareMinor: 10250,
        quantity: 10,
        totalAmountMinor: 102500,
        isSimulated: true,
        executedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  late List<TradableSecurity> _securities;
  late List<ShareHolding> _holdings;
  late List<TradeOrder> _orders;
  late List<TradeExecution> _trades;

  @override
  Future<List<TradableSecurity>> getTradableSecurities() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_securities);
  }

  @override
  Future<List<ShareHolding>> getShareHoldings() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_holdings);
  }

  @override
  Future<List<TradeOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_orders);
  }

  @override
  Future<List<TradeExecution>> getTrades() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_trades);
  }

  @override
  Future<PlaceOrderResult> placeOrder({
    required String ipoId,
    required String side,
    required int quantity,
    required int pricePerShareMinor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sec = _securities.firstWhere(
      (s) => s.ipoId == ipoId,
      orElse: () => TradableSecurity(
        ipoId: ipoId,
        symbol: 'SECR',
        companyName: 'Company S.C.',
        status: 'listed',
        pricePerShareMinor: pricePerShareMinor,
        totalTrades: 0,
        openOrdersCount: 0,
      ),
    );

    final newOrder = TradeOrder(
      id: 'mock-order-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock-user-1',
      ipoId: ipoId,
      symbol: sec.symbol,
      companyName: sec.companyName,
      side: side,
      orderType: 'limit',
      pricePerShareMinor: pricePerShareMinor,
      quantity: quantity,
      filledQuantity: 0,
      status: 'open',
      reservedAmountMinor: side == 'buy' ? quantity * pricePerShareMinor : 0,
      isSimulated: true,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, newOrder);

    // If selling, reserve shares in holding
    if (side == 'sell') {
      final hIdx = _holdings.indexWhere((h) => h.ipoId == ipoId);
      if (hIdx >= 0) {
        final existing = _holdings[hIdx];
        _holdings[hIdx] = ShareHolding(
          id: existing.id,
          investorId: existing.investorId,
          ipoId: existing.ipoId,
          quantity: existing.quantity,
          reservedQuantity: existing.reservedQuantity + quantity,
          symbol: existing.symbol,
          companyName: existing.companyName,
          pricePerShareMinor: existing.pricePerShareMinor,
        );
      }
    }

    return PlaceOrderResult(order: newOrder, executions: const []);
  }

  @override
  Future<TradeOrder> cancelOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw Exception('Order not found');

    final o = _orders[idx];
    final updated = TradeOrder(
      id: o.id,
      userId: o.userId,
      assistedByBrokerId: o.assistedByBrokerId,
      ipoId: o.ipoId,
      symbol: o.symbol,
      companyName: o.companyName,
      side: o.side,
      orderType: o.orderType,
      pricePerShareMinor: o.pricePerShareMinor,
      quantity: o.quantity,
      filledQuantity: o.filledQuantity,
      status: 'cancelled',
      reservedAmountMinor: 0,
      isSimulated: o.isSimulated,
      createdAt: o.createdAt,
    );

    _orders[idx] = updated;

    // Release shares if sell
    if (o.side == 'sell') {
      final hIdx = _holdings.indexWhere((h) => h.ipoId == o.ipoId);
      if (hIdx >= 0) {
        final existing = _holdings[hIdx];
        _holdings[hIdx] = ShareHolding(
          id: existing.id,
          investorId: existing.investorId,
          ipoId: existing.ipoId,
          quantity: existing.quantity,
          reservedQuantity:
              (existing.reservedQuantity - o.quantity).clamp(0, existing.quantity),
          symbol: existing.symbol,
          companyName: existing.companyName,
          pricePerShareMinor: existing.pricePerShareMinor,
        );
      }
    }

    return updated;
  }
}
