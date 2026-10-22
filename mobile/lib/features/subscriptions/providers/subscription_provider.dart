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
  Object? _error;
  SubscriptionModel? _lastCreated;

  bool get isSubmitting => _isSubmitting;
  Object? get error => _error;
  SubscriptionModel? get lastCreated => _lastCreated;

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
