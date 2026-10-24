import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import '../repositories/subscription_repository.dart';

class SubscriptionsProvider extends ChangeNotifier {
  SubscriptionsProvider({required SubscriptionsRepository repository})
      : _repository = repository;

  final SubscriptionsRepository _repository;

  List<AdminSubscription> _subscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;
  AdminSubscription? _selectedSubscription;

  List<AdminSubscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminSubscription? get selectedSubscription => _selectedSubscription;

  // Aggregate metrics
  int get totalSubscriptions => _subscriptions.length;
  int get totalRequestedShares =>
      _subscriptions.fold(0, (sum, s) => sum + s.quantity);
  int get totalAllocatedShares =>
      _subscriptions.fold(0, (sum, s) => sum + s.allocatedQuantity);
  int get totalCommittedValueMinor =>
      _subscriptions.fold(0, (sum, s) => sum + s.totalAmountMinor);

  double oversubscriptionRatio(int totalOfferedShares) {
    if (totalOfferedShares <= 0) return 0.0;
    return (totalRequestedShares / totalOfferedShares) * 100.0;
  }

  Future<void> loadSubscriptions({String? ipoId, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscriptions = await _repository.getSubscriptions(
        ipoId: ipoId,
        status: status,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubscriptionById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedSubscription = null;
    notifyListeners();

    try {
      _selectedSubscription = await _repository.getSubscriptionById(id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedSubscription = null;
    notifyListeners();
  }
}
