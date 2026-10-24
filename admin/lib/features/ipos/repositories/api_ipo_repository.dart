import '../../../core/network/api_client.dart';
import '../models/ipo_application.dart';
import 'ipo_repository.dart';

/// Live implementation of [IpoRepository] calling backend endpoints.
class ApiIpoRepository implements IpoRepository {
  ApiIpoRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<IpoApplication>> getApplications() async {
    final response = await _apiClient.get('/ipos');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => IpoApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<IpoApplication> getApplicationById(String id) async {
    final response = await _apiClient.get('/ipos/$id');
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return IpoApplication.fromJson(data);
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    await _apiClient.post('/admin/ipos/$id/approve', body);
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await _apiClient.post('/admin/ipos/$id/reject', {
      'reason': reason,
    });
  }

  @override
  Future<void> closeIpo(String id, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }
    await _apiClient.post('/admin/ipos/$id/close', body);
  }

  @override
  Future<void> allocateIpo(String id) async {
    await _apiClient.post('/admin/ipos/$id/allocate', {});
  }
}
