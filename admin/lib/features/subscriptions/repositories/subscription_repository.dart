import '../models/subscription_model.dart';

abstract class SubscriptionsRepository {
  Future<List<AdminSubscription>> getSubscriptions({
    String? ipoId,
    String? status,
    int? page,
    int? pageSize,
  });

  Future<AdminSubscription> getSubscriptionById(String id);
}
