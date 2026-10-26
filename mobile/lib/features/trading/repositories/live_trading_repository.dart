import '../../../core/network/api_client.dart';
import '../models/trading_models.dart';
import 'trading_repository.dart';

class LiveTradingRepository implements TradingRepository {
  const LiveTradingRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  @override
  Future<List<TradableSecurity>> getTradableSecurities() async {
    final response = await _client.get<dynamic>('/trading/securities');
    final List<dynamic> list;
    if (response is Map<String, dynamic> && response['data'] is List) {
      list = response['data'] as List<dynamic>;
    } else if (response is List) {
      list = response;
    } else {
      list = const [];
    }
    return list
        .map((item) =>
            TradableSecurity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ShareHolding>> getShareHoldings() async {
    final response = await _client.get<dynamic>('/trading/holdings');
    final List<dynamic> list;
    if (response is Map<String, dynamic> && response['data'] is List) {
      list = response['data'] as List<dynamic>;
    } else if (response is List) {
      list = response;
    } else {
      list = const [];
    }
    return list
        .map((item) => ShareHolding.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TradeOrder>> getOrders() async {
    final response = await _client.get<dynamic>('/trading/orders');
    final List<dynamic> list;
    if (response is Map<String, dynamic> && response['data'] is List) {
      list = response['data'] as List<dynamic>;
    } else if (response is List) {
      list = response;
    } else {
      list = const [];
    }
    return list
        .map((item) => TradeOrder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TradeExecution>> getTrades() async {
    final response = await _client.get<dynamic>('/trading/trades');
    final List<dynamic> list;
    if (response is Map<String, dynamic> && response['data'] is List) {
      list = response['data'] as List<dynamic>;
    } else if (response is List) {
      list = response;
    } else {
      list = const [];
    }
    return list
        .map((item) => TradeExecution.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PlaceOrderResult> placeOrder({
    required String ipoId,
    required String side,
    required int quantity,
    required int pricePerShareMinor,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/trading/orders',
      data: {
        'ipo_id': ipoId,
        'side': side,
        'order_type': 'limit',
        'quantity': quantity,
        'price_per_share_minor': pricePerShareMinor,
      },
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return PlaceOrderResult.fromJson(data);
  }

  @override
  Future<TradeOrder> cancelOrder(String orderId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/trading/orders/$orderId/cancel',
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : (response['order'] is Map<String, dynamic>
            ? response['order'] as Map<String, dynamic>
            : response);
    return TradeOrder.fromJson(data);
  }
}
