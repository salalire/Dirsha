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
  factory ApiException.unauthorized() => const ApiException(
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
        isUnauthorized: true,
      );

  /// Factory: 403 Forbidden — authenticated but not permitted.
  factory ApiException.forbidden() => const ApiException(
        message: 'You do not have permission to perform this action.',
        statusCode: 403,
        isForbidden: true,
      );

  /// Factory: unexpected HTTP status.
  factory ApiException.fromStatus(int statusCode, String body) {
    return ApiException(
      message: _messageFromStatus(statusCode, body),
      statusCode: statusCode,
    );
  }

  static String _messageFromStatus(int code, String body) {
    switch (code) {
      case 400:
        return 'Invalid request. Please check your input.';
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
  String toString() => 'ApiException($statusCode): $message';
}
