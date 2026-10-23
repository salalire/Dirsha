/// Represents a typed API error so the UI can react appropriately.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
    this.isUnauthorized = false,
    this.isForbidden = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final bool isUnauthorized;
  final bool isForbidden;

  /// Factory: network/timeout failure (no HTTP response received).
  factory ApiException.network() => const ApiException(
        message: 'Network error. Please check your connection and try again.',
        isNetworkError: true,
      );

  /// Factory: 401 Unauthorized — session expired or invalid credentials.
  factory ApiException.unauthorized([String? customMessage]) => ApiException(
        message: customMessage ?? 'Your session has expired. Please sign in again.',
        statusCode: 401,
        isUnauthorized: true,
      );

  /// Factory: 403 Forbidden — authenticated but not permitted.
  factory ApiException.forbidden([String? customMessage]) => ApiException(
        message: customMessage ?? 'You do not have permission to perform this action.',
        statusCode: 403,
        isForbidden: true,
      );

  /// Factory: unexpected HTTP status.
  factory ApiException.fromStatus(int statusCode, String body) {
    return ApiException(
      message: messageFromStatus(statusCode, body),
      statusCode: statusCode,
    );
  }

  static String messageFromStatus(int code, [String? body]) {
    switch (code) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Invalid email or password.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This action conflicts with the current state.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return 'Unexpected error (HTTP $code).';
    }
  }

  @override
  String toString() => message;
}
