// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage keys — defined once to avoid typos across the codebase.
abstract final class AuthStorageKeys {
  static const String accessToken = 'dirsha_access_token';
  static const String refreshToken = 'dirsha_refresh_token';
}

/// Attaches the Bearer access token to outgoing requests and handles
/// 401 responses by attempting a token refresh.
///
/// Security notes:
/// - Tokens are stored in [FlutterSecureStorage] (Keychain on iOS,
///   EncryptedSharedPreferences on Android).
/// - Tokens are NEVER written to logs or debug output.
/// - If the refresh attempt also fails with 401, all stored tokens are
///   cleared and the [onUnauthenticated] callback is invoked so the app
///   can navigate the user back to sign-in.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required FlutterSecureStorage storage,
    required Dio dio,
    required VoidCallback onUnauthenticated,
  }) : _storage = storage,
       _dio = dio,
       _onUnauthenticated = onUnauthenticated;

  final FlutterSecureStorage _storage;
  final Dio _dio;
  final VoidCallback _onUnauthenticated;

  // Prevents concurrent refresh attempts when multiple requests 401 at once.
  bool _isRefreshing = false;

  // ---------------------------------------------------------------------------
  // Outgoing request — attach access token
  // ---------------------------------------------------------------------------

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AuthStorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ---------------------------------------------------------------------------
  // Error response — handle 401
  // ---------------------------------------------------------------------------

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    if (response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          // Retry the original request with the new token.
          final newToken = await _storage.read(
            key: AuthStorageKeys.accessToken,
          );
          final retryOptions = err.requestOptions
            ..headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        // Refresh failed — fall through to clearing tokens.
      } finally {
        _isRefreshing = false;
      }

      await _clearTokens();
      _onUnauthenticated();
    }

    handler.next(err);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<bool> _attemptRefresh() async {
    final refreshToken = await _storage.read(key: AuthStorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    // NOTE: The refresh endpoint path must match the agreed API contract
    // from Member 2.  It is declared here as a constant so it is easy to
    // update when the contract is finalized.
    const refreshPath = '/auth/refresh';

    final response = await _dio.post<Map<String, dynamic>>(
      refreshPath,
      data: {'refreshToken': refreshToken},
      options: Options(
        // Skip the auth interceptor on the refresh request itself to avoid
        // an infinite loop.
        extra: {'skipAuthInterceptor': true},
      ),
    );

    final data = response.data;
    if (data == null) return false;

    // Parse new tokens from the agreed response shape:
    // { "accessToken": "...", "refreshToken": "..." }
    final newAccess = data['accessToken'] as String?;
    final newRefresh = data['refreshToken'] as String?;

    if (newAccess == null || newAccess.isEmpty) return false;

    await _storage.write(key: AuthStorageKeys.accessToken, value: newAccess);
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await _storage.write(
        key: AuthStorageKeys.refreshToken,
        value: newRefresh,
      );
    }

    return true;
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AuthStorageKeys.accessToken);
    await _storage.delete(key: AuthStorageKeys.refreshToken);
  }

  /// Persists tokens after a successful sign-in or registration.
  ///
  /// Called by the auth repository; not called from within this interceptor.
  Future<void> saveTokens({
    required String accessToken,
    required String? refreshToken,
  }) async {
    await _storage.write(key: AuthStorageKeys.accessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(
        key: AuthStorageKeys.refreshToken,
        value: refreshToken,
      );
    }
  }

  /// Clears all stored tokens on explicit sign-out.
  Future<void> clearTokens() => _clearTokens();

  /// Returns true if an access token is currently stored.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: AuthStorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }
}
