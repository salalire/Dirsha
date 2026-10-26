// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../models/trading_models.dart';
import '../repositories/trading_repository.dart';

class TradingProvider extends ChangeNotifier {
  TradingProvider({required TradingRepository repository})
      : _repository = repository;

  final TradingRepository _repository;

  List<TradableSecurity> _securities = [];
  List<ShareHolding> _holdings = [];
  List<TradeOrder> _orders = [];
  List<TradeExecution> _trades = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  Object? _error;
  String? _actionSuccessMessage;

  List<TradableSecurity> get securities => _securities;
  List<ShareHolding> get holdings => _holdings;
  List<TradeOrder> get orders => _orders;
  List<TradeExecution> get trades => _trades;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  Object? get error => _error;
  String? get actionSuccessMessage => _actionSuccessMessage;

  String? get errorMessage {
    if (_error == null) return null;
    if (_error is AppException) return (_error as AppException).message;
    return _error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getTradableSecurities(),
        _repository.getShareHoldings(),
        _repository.getOrders(),
        _repository.getTrades(),
      ]);

      _securities = results[0] as List<TradableSecurity>;
      _holdings = results[1] as List<ShareHolding>;
      _orders = results[2] as List<TradeOrder>;
      _trades = results[3] as List<TradeExecution>;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _error = null;
    try {
      final results = await Future.wait([
        _repository.getTradableSecurities(),
        _repository.getShareHoldings(),
        _repository.getOrders(),
        _repository.getTrades(),
      ]);

      _securities = results[0] as List<TradableSecurity>;
      _holdings = results[1] as List<ShareHolding>;
      _orders = results[2] as List<TradeOrder>;
      _trades = results[3] as List<TradeExecution>;
    } catch (e) {
      _error = e;
    } finally {
      notifyListeners();
    }
  }

  Future<PlaceOrderResult?> placeOrder({
    required String ipoId,
    required String side,
    required int quantity,
    required int pricePerShareMinor,
  }) async {
    _isSubmitting = true;
    _error = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final result = await _repository.placeOrder(
        ipoId: ipoId,
        side: side,
        quantity: quantity,
        pricePerShareMinor: pricePerShareMinor,
      );

      if (result.executions.isNotEmpty) {
        _actionSuccessMessage =
            'Order executed immediately (${result.executions.length} match)!';
      } else {
        _actionSuccessMessage =
            'Limit ${side.toUpperCase()} order placed successfully.';
      }

      await refresh();
      return result;
    } catch (e) {
      _error = e;
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    _isSubmitting = true;
    _error = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      await _repository.cancelOrder(orderId);
      _actionSuccessMessage = 'Order cancelled and reserved assets released.';
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _actionSuccessMessage = null;
    _error = null;
    notifyListeners();
  }
}
