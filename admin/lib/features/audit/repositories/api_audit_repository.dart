import '../../../core/network/api_client.dart';
import '../models/audit_event.dart';
import 'audit_repository.dart';

/// Live implementation of [AuditRepository] calling backend `/admin/audit`.
class ApiAuditRepository implements AuditRepository {
  ApiAuditRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<AuditEvent>> getRecentEvents({
    int limit = 50,
    String? action,
    String? actorUserId,
  }) async {
    final params = <String>[
      'page=1',
      'page_size=$limit',
      if (action != null && action.isNotEmpty) 'action=${Uri.encodeComponent(action)}',
      if (actorUserId != null && actorUserId.isNotEmpty)
        'actor_user_id=${Uri.encodeComponent(actorUserId)}',
    ];
    final queryString = params.join('&');
    final response = await _apiClient.get('/admin/audit?$queryString');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AuditEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
