// ignore_for_file: prefer_initializing_formals
import 'dart:math';
import '../../../core/errors/app_exception.dart';
import '../../wallet/repositories/wallet_repository.dart';
import '../models/subscription_models.dart';
import 'subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  MockSubscriptionRepository({WalletRepository? walletRepository})
      : _walletRepository = walletRepository;

  final WalletRepository? _walletRepository;
  final List<SubscriptionModel> _subscriptions = [];
  final Map<String, SubscriptionModel> _idempotentStore = {};

  @override
  Future<SubscriptionModel> createSubscription({
    required String ipoId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Check idempotency replay
    if (_idempotentStore.containsKey(idempotencyKey)) {
      final existing = _idempotentStore[idempotencyKey]!;
      if (existing.ipoId == ipoId && existing.quantity == quantity) {
        return existing;
      }
      throw const ApiException(
        message: 'This Idempotency-Key was already used with a different request',
        statusCode: 409,
        errorCode: 'IDEMPOTENCY_KEY_REUSED',
      );
    }

    // Check single active subscription rule (B4)
    final hasActive = _subscriptions.any(
      (s) =>
          s.ipoId == ipoId &&
          (s.status == SubscriptionStatus.reserved ||
              s.status == SubscriptionStatus.allocated ||
              s.status == SubscriptionStatus.partiallyAllocated),
    );
    if (hasActive) {
      throw const ApiException(
        message: 'An active subscription already exists for this IPO',
        statusCode: 409,
        errorCode: 'CONFLICT',
      );
    }

    // Default mock price: 100 ETB (10000 santim) per share
    const pricePerShareMinor = 10000;
    final amountMinor = quantity * pricePerShareMinor;

    if (_walletRepository != null) {
      final wallet = await _walletRepository.getWalletSummary();
      if (wallet.available.santim < amountMinor) {
        throw const ApiException(
          message: 'Available balance is not enough for this operation',
          statusCode: 422,
          errorCode: 'INSUFFICIENT_FUNDS',
        );
      }
    }

    final now = DateTime.now();
    final sub = SubscriptionModel(
      id: 'sub-mock-${Random().nextInt(999999)}',
      ipoId: ipoId,
      investorId: 'mock-investor',
      quantity: quantity,
      amountMinor: amountMinor,
      allocatedQuantity: 0,
      status: SubscriptionStatus.reserved,
      reservationLedgerEntryId: 'ledger-mock-${Random().nextInt(999999)}',
      createdAt: now,
      updatedAt: now,
    );

    _subscriptions.insert(0, sub);
    _idempotentStore[idempotencyKey] = sub;
    return sub;
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions({
    String? ipoId,
    SubscriptionStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var list = _subscriptions;
    if (ipoId != null) {
      list = list.where((s) => s.ipoId == ipoId).toList();
    }
    if (status != null) {
      list = list.where((s) => s.status == status).toList();
    }
    return List.unmodifiable(list);
  }

  @override
  Future<SubscriptionModel> getSubscriptionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _subscriptions.firstWhere(
      (s) => s.id == id,
      orElse: () => throw const ApiException(
        message: 'Subscription not found',
        statusCode: 404,
        errorCode: 'NOT_FOUND',
      ),
    );
  }
}
