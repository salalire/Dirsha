import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/subscription_models.dart';
import 'subscription_repository.dart';

class LiveSubscriptionRepository implements SubscriptionRepository {
  const LiveSubscriptionRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  @override
  Future<SubscriptionModel> createSubscription({
    required String ipoId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/subscriptions',
      data: {
        'ipo_id': ipoId,
        'quantity': quantity,
      },
      options: Options(
        headers: {
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    final data = response['data'] as Map<String, dynamic>;
    return SubscriptionModel.fromJson(data);
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions({
    String? ipoId,
    SubscriptionStatus? status,
  }) async {
    final queryParams = <String, String>{};
    if (ipoId != null) queryParams['ipo_id'] = ipoId;
    if (status != null && status != SubscriptionStatus.unknown) {
      queryParams['status'] = status.name;
    }

    final response = await _client.get(
      '/subscriptions',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SubscriptionModel> getSubscriptionById(String id) async {
    final response = await _client.get('/subscriptions/$id');
    final data = response['data'] as Map<String, dynamic>;
    return SubscriptionModel.fromJson(data);
  }
}
