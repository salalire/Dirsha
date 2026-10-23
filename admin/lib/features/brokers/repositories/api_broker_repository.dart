import '../../../core/network/api_client.dart';
import '../models/broker_application.dart';
import 'broker_repository.dart';

/// Live implementation of [BrokerRepository] calling backend endpoints.
class ApiBrokerRepository implements BrokerRepository {
  ApiBrokerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<BrokerApplication>> getApplications() async {
    final response = await _apiClient.get('/admin/brokers');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) =>
            BrokerApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BrokerApplication> getApplicationById(String id) async {
    final response = await _apiClient.get('/admin/brokers/$id');
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return BrokerApplication.fromJson(data);
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    await _apiClient.post('/admin/brokers/$id/approve', body);
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await _apiClient.post('/admin/brokers/$id/reject', {
      'reason': reason,
    });
  }

  @override
  Future<void> requestAdditionalInfo(String id, {required String message}) async {
    await _apiClient.post('/admin/brokers/$id/request-info', {
      'message': message,
    });
  }

  @override
  Future<void> reviewDocument(
      String documentId, {required String status, String? notes}) async {
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    await _apiClient.post('/admin/documents/$documentId/review', body);
  }
}
