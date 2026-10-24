// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../models/subscription_models.dart';
import '../repositories/subscription_repository.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({required SubscriptionRepository repository})
      : _repository = repository;

  final SubscriptionRepository _repository;

  bool _isSubmitting = false;
  bool _isLoading = false;
  Object? _error;
  SubscriptionModel? _lastCreated;
  List<SubscriptionModel> _subscriptions = [];
  SubscriptionStatus? _statusFilter;

  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  SubscriptionModel? get lastCreated => _lastCreated;
  List<SubscriptionModel> get subscriptions => List.unmodifiable(_subscriptions);
  SubscriptionStatus? get statusFilter => _statusFilter;

  String? get errorMessage {
    if (_error == null) return null;
    if (_error is AppException) return (_error as AppException).message;
    return _error.toString();
  }

  String? get errorCode {
    if (_error is ApiException) return (_error as ApiException).errorCode;
    return null;
  }

  bool get isInsufficientFunds => errorCode == 'INSUFFICIENT_FUNDS';
  bool get isIpoNotOpen => errorCode == 'IPO_NOT_OPEN';
  bool get isConflict => errorCode == 'CONFLICT';

  Future<void> loadSubscriptions({
    String? ipoId,
    SubscriptionStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    _statusFilter = status;
    notifyListeners();

    try {
      final list = await _repository.getSubscriptions(
        ipoId: ipoId,
        status: status,
      );
      _subscriptions = list;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadSubscriptions(status: _statusFilter);
  }

  Future<SubscriptionModel?> getSubscriptionDetails(String id) async {
    try {
      return await _repository.getSubscriptionById(id);
    } catch (e) {
      _error = e;
      notifyListeners();
      return null;
    }
  }

  Future<SubscriptionModel?> submitSubscription({
    required String ipoId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final sub = await _repository.createSubscription(
        ipoId: ipoId,
        quantity: quantity,
        idempotencyKey: idempotencyKey,
      );
      _lastCreated = sub;
      // Prepend to subscriptions list if loaded
      _subscriptions = [sub, ..._subscriptions.where((s) => s.id != sub.id)];
      return sub;
    } on AppException catch (e) {
      _error = e;
      return null;
    } catch (e) {
      _error = e;
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
