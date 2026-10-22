import '../../../core/network/api_client.dart';
import '../models/user_application.dart';
import 'user_repository.dart';

/// Live implementation of [UserRepository] calling backend `/admin/users`.
class ApiUserRepository implements UserRepository {
  ApiUserRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<UserApplication>> getApplications() async {
    final response = await _apiClient.get('/admin/users');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => UserApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserApplication> getApplicationById(String id) async {
    final apps = await getApplications();
    return apps.firstWhere(
      (app) => app.id == id,
      orElse: () => throw Exception('User not found: $id'),
    );
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    // KYC/Identity approval is deferred to post-MVP per Part B rules
    throw UnsupportedError('User application approval is deferred post-MVP.');
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    // KYC/Identity rejection is deferred to post-MVP per Part B rules
    throw UnsupportedError('User application rejection is deferred post-MVP.');
  }
}
