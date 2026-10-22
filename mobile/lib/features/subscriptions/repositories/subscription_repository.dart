import '../models/subscription_models.dart';

abstract interface class SubscriptionRepository {
  Future<SubscriptionModel> createSubscription({
    required String ipoId,
    required int quantity,
    required String idempotencyKey,
  });

  Future<List<SubscriptionModel>> getSubscriptions({
    String? ipoId,
    SubscriptionStatus? status,
  });

  Future<SubscriptionModel> getSubscriptionById(String id);
}
