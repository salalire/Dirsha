import '../../../core/network/api_client.dart';
import '../models/company_application.dart';
import 'company_repository.dart';

/// Live implementation of [CompanyRepository] calling backend endpoints.
class ApiCompanyRepository implements CompanyRepository {
  ApiCompanyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<CompanyApplication>> getApplications() async {
    final response = await _apiClient.get('/admin/companies');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) =>
            CompanyApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CompanyApplication> getApplicationById(String id) async {
    final response = await _apiClient.get('/admin/companies/$id');
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return CompanyApplication.fromJson(data);
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    await _apiClient.post('/admin/companies/$id/approve', body);
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await _apiClient.post('/admin/companies/$id/reject', {
      'reason': reason,
    });
  }

  @override
  Future<void> requestAdditionalInfo(String id, {required String message}) async {
    await _apiClient.post('/admin/companies/$id/request-info', {
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
