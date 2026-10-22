import '../../../core/network/api_client.dart';
import '../models/audit_event.dart';
import 'audit_repository.dart';

/// Live implementation of [AuditRepository] calling backend `/admin/audit`.
class ApiAuditRepository implements AuditRepository {
  ApiAuditRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<AuditEvent>> getRecentEvents({int limit = 50}) async {
    final response = await _apiClient.get('/admin/audit?page=1&page_size=$limit');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AuditEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
