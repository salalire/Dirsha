import '../../../core/network/api_client.dart';
import '../models/subscription_model.dart';
import 'subscription_repository.dart';

class ApiSubscriptionsRepository implements SubscriptionsRepository {
  ApiSubscriptionsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<AdminSubscription>> getSubscriptions({
    String? ipoId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    final queryParams = <String>[];
    if (ipoId != null && ipoId.isNotEmpty) {
      queryParams.add('ipo_id=${Uri.encodeComponent(ipoId)}');
    }
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    if (page != null) {
      queryParams.add('page=$page');
    }
    if (pageSize != null) {
      queryParams.add('page_size=$pageSize');
    }

    final queryStr = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await _apiClient.get('/subscriptions$queryStr');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AdminSubscription.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminSubscription> getSubscriptionById(String id) async {
    final response = await _apiClient.get('/subscriptions/$id');
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return AdminSubscription.fromJson(data);
  }
}
