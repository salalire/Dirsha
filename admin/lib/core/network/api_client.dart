import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_exception.dart';

/// HTTP client wrapper for all API calls.
///
/// Automatically attaches the Authorization header when a token is available.
/// Parses error responses into [ApiException] so calling code stays clean.
///
/// Usage:
///   final client = ApiClient();
///   client.setToken(token);
///   final data = await client.get('/admin/ipos');
class ApiClient {
  ApiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;
  String? _token;

  /// Sets the bearer token for subsequent requests.
  /// Call this after a successful sign-in.
  void setToken(String token) {
    _token = token;
  }

  /// Clears the stored token. Call on sign-out.
  void clearToken() {
    _token = null;
  }

  bool get hasToken => _token != null;

  // ── Request helpers ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(String path) async {
    return _send('GET', path, null);
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    return _send('POST', path, body);
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    return _send('PUT', path, body);
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    return _send('PATCH', path, body);
  }

  // ── Core send ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(AppConfig.requestTimeout);
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: json.encode(body))
              .timeout(AppConfig.requestTimeout);
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: json.encode(body))
              .timeout(AppConfig.requestTimeout);
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: json.encode(body))
              .timeout(AppConfig.requestTimeout);
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.network();
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        if (response.body.isEmpty) return {};
        return json.decode(response.body) as Map<String, dynamic>;
      case 401:
        throw ApiException.unauthorized();
      case 403:
        throw ApiException.forbidden();
      default:
        throw ApiException.fromStatus(response.statusCode, response.body);
    }
  }
}
