import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_models.dart';
import 'auth_repository.dart';

/// Live implementation of [AuthRepository] — calls the real Dirsha backend.
///
/// STATUS: Not yet active. Replaces [MockAuthRepository] once:
///   1. Member 2 confirms endpoint paths and response schemas.
///   2. POST /auth/login and POST /auth/register are deployed and reachable.
///   3. [AppConfig.useMockRepositories] is set to false.
///
/// Agreed endpoints (pending confirmation with Member 2):
///   POST /auth/register  → AuthResult
///   POST /auth/login     → AuthResult
///   POST /auth/logout    → 204 No Content
///   GET  /users/me       → UserProfile
///
/// DEPENDENCY ON MEMBER 2:
///   - Confirm exact JSON field names.
///   - Confirm error response shape { message, error, statusCode }.
///   - Confirm refresh token behavior and rotation strategy.
class LiveAuthRepository implements AuthRepository {
  const LiveAuthRepository({required ApiClient apiClient})
    : _client = apiClient;

  final ApiClient _client;

  @override
  Future<AuthResult> login(LoginRequest request) async {
    final data = await _client.post<Map<String, dynamic>?>(
      '/auth/login',
      data: request.toJson(),
    );
    if (data == null) {
      throw const ParseException(message: 'Login response was empty.');
    }
    try {
      final result = AuthResult.fromJson(data);
      await _client.auth.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      return result;
    } catch (e) {
      throw ParseException(
        message: 'Could not parse login response.',
        cause: e,
      );
    }
  }

  @override
  Future<AuthResult> register(RegisterRequest request) async {
    final data = await _client.post<Map<String, dynamic>?>(
      '/auth/register',
      data: request.toJson(),
    );
    if (data == null) {
      throw const ParseException(message: 'Register response was empty.');
    }
    try {
      final unwrapped = (data['data'] is Map<String, dynamic>)
          ? data['data'] as Map<String, dynamic>
          : data;
      if (unwrapped.containsKey('access_token') ||
          unwrapped.containsKey('accessToken')) {
        final result = AuthResult.fromJson(data);
        await _client.auth.saveTokens(
          accessToken: result.tokens.accessToken,
          refreshToken: result.tokens.refreshToken,
        );
        return result;
      }
      // Standard backend behavior: POST /auth/register returns created user,
      // then immediately log in with credentials to establish session
      return await login(
        LoginRequest(email: request.email, password: request.password),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(
        message: 'Could not parse registration response.',
        cause: e,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post<void>('/auth/logout');
    } on AppException {
      // Best-effort server logout. Always clear local tokens regardless.
    } catch (_) {
      // Ignore network errors on logout
    }
    await _client.auth.clearTokens();
  }

  @override
  Future<UserProfile> getCurrentUser() async {
    final data = await _client.get<Map<String, dynamic>?>('/users/me');
    if (data == null) {
      throw const ParseException(message: 'User profile response was empty.');
    }
    try {
      final payload = (data['data'] is Map<String, dynamic>)
          ? data['data'] as Map<String, dynamic>
          : data;
      return UserProfile.fromJson(payload);
    } catch (e) {
      throw ParseException(message: 'Could not parse user profile.', cause: e);
    }
  }
}
