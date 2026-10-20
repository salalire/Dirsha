/// Base class for all application-level exceptions.
///
/// Distinguishes network failures, API errors, and client-side problems
/// from each other so the UI can present appropriate messages and actions.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

// ---------------------------------------------------------------------------
// Network-level failures
// ---------------------------------------------------------------------------

/// The device could not reach the server (no connectivity, DNS failure,
/// timeout, etc.).  The server did NOT return a response.
///
/// Must be shown to the user as a network/connectivity problem — never
/// silently substituted with mock data.
final class NetworkException extends AppException {
  const NetworkException({String message = 'No connection to the server.'})
    : super(message);
}

/// The request timed out before the server responded.
final class TimeoutException extends AppException {
  const TimeoutException({String message = 'The request timed out.'})
    : super(message);
}

// ---------------------------------------------------------------------------
// API-level failures (server returned a response)
// ---------------------------------------------------------------------------

/// The server returned an HTTP error response.
///
/// [statusCode] is the HTTP status.
/// [serverMessage] is the human-readable detail from the response body,
/// already stripped of any sensitive content.
final class ApiException extends AppException {
  const ApiException({
    required this.statusCode,
    required String message,
    this.serverMessage,
    this.errorCode,
  }) : super(message);

  final int statusCode;

  /// Developer-facing detail from the response body (never logged verbatim
  /// in production; shown to the user only when it is safe to do so).
  final String? serverMessage;

  /// Machine-readable error code from the agreed API contract, e.g.
  /// "INSUFFICIENT_FUNDS" or "IPO_CLOSED".
  final String? errorCode;
}

/// The server returned 401 — the session has expired or the token is invalid.
/// The app should redirect the user to the sign-in screen.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    String message = 'Your session has expired. Please sign in again.',
  }) : super(message);
}

/// The server returned 403 — the authenticated user lacks permission.
final class ForbiddenException extends AppException {
  const ForbiddenException({
    String message = 'You do not have permission to perform this action.',
  }) : super(message);
}

/// The server returned 404.
final class NotFoundException extends AppException {
  const NotFoundException({
    String message = 'The requested item was not found.',
  }) : super(message);
}

/// The server returned 422 or 400 with validation detail.
final class ValidationException extends AppException {
  const ValidationException({
    required String message,
    this.fieldErrors = const {},
  }) : super(message);

  /// Per-field validation messages keyed by field name, as returned by the
  /// agreed API contract.  Empty when the server returns only a top-level
  /// message.
  final Map<String, String> fieldErrors;
}

// ---------------------------------------------------------------------------
// Client-side problems
// ---------------------------------------------------------------------------

/// Response JSON could not be parsed into the expected model.
/// This usually means the API contract has drifted; report it as a bug.
final class ParseException extends AppException {
  const ParseException({
    String message = 'Could not parse the server response.',
    this.cause,
  }) : super(message);

  final Object? cause;
}

/// An operation was attempted that is not valid in the current state, e.g.
/// trying to subscribe to a closed IPO from the client side.
final class InvalidOperationException extends AppException {
  const InvalidOperationException(super.message);
}
