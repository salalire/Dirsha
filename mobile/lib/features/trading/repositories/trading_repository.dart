import '../models/trading_models.dart';

abstract class TradingRepository {
  /// Fetches only listed securities eligible for secondary-market trading.
  Future<List<TradableSecurity>> getTradableSecurities();

  /// Fetches the authenticated investor's share holdings.
  Future<List<ShareHolding>> getShareHoldings();

  /// Fetches orders placed by the authenticated investor.
  Future<List<TradeOrder>> getOrders();

  /// Fetches trade executions executed by the authenticated investor.
  Future<List<TradeExecution>> getTrades();

  /// Places a limit buy or sell order.
  Future<PlaceOrderResult> placeOrder({
    required String ipoId,
    required String side,
    required int quantity,
    required int pricePerShareMinor,
  });

  /// Cancels an open or partially filled order.
  Future<TradeOrder> cancelOrder(String orderId);
}
