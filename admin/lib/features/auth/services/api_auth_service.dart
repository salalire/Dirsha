import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_user.dart';
import 'auth_service.dart';

/// Real implementation of [AuthService] talking to Member 2's backend.
///
/// Communicates with `/auth/login` and persists the access token.
class ApiAuthService implements AuthService {
  ApiAuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String _tokenPrefKey = 'dirsha_admin_token';
  static const String _userPrefKey = 'dirsha_admin_user';

  @override
  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final payload = (response['data'] is Map<String, dynamic>)
        ? response['data'] as Map<String, dynamic>
        : response;
    final token = payload['access_token'] as String? ?? payload['token'] as String?;
    final userData = payload['user'] as Map<String, dynamic>?;

    if (token == null || userData == null) {
      throw Exception('Unexpected server response: missing token or user data');
    }

    final user = AdminUser.fromJson(userData);

    // Save token to ApiClient
    _apiClient.setToken(token);

    // Persist session to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefKey, token);
    await prefs.setString(_userPrefKey, json.encode(userData));

    return user;
  }

  @override
  Future<void> signOut() async {
    _apiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
    await prefs.remove(_userPrefKey);
  }

  @override
  Future<AdminUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefKey);
    final rawUser = prefs.getString(_userPrefKey);

    if (token == null || rawUser == null) {
      return null;
    }

    _apiClient.setToken(token);

    try {
      final map = json.decode(rawUser) as Map<String, dynamic>;
      return AdminUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
