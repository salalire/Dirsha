/// Dirsha mobile application configuration.
///
/// The API base URL is read from the compile-time `--dart-define` flag
/// `DIRSHA_API_BASE_URL` so that development, staging, and production
/// builds can each point at the correct backend without changing source
/// code or committing real URLs.
///
/// Usage examples:
///
///   # Development (Member 2's local backend)
///   flutter run --dart-define=DIRSHA_API_BASE_URL=http://10.0.2.2:3000/api \
///               --dart-define=DIRSHA_ENV=development
///
///   # Staging / CI
///   flutter run --dart-define=DIRSHA_API_BASE_URL=https://api.staging.dirsha.com/api \
///               --dart-define=DIRSHA_ENV=staging
///
/// IMPORTANT: Do NOT hardcode a developer's local IP address here.
/// IMPORTANT: Never put real secrets or credentials inside this file.
///
/// If no `--dart-define` value is provided the app defaults to the
/// development placeholder below, which will result in network errors
/// until the actual URL is supplied.  This is intentional: the app
/// must not silently substitute mock data when a real URL was expected.
abstract final class AppConfig {
  // ---------------------------------------------------------------------------
  // Compile-time values injected via --dart-define
  // ---------------------------------------------------------------------------

  /// Backend API base URL. Injected at build time; has no default that
  /// points at any real server.
  static const String apiBaseUrl = String.fromEnvironment(
    'DIRSHA_API_BASE_URL',
    // Placeholder default — this will fail gracefully with a network error
    // so the developer notices that the URL has not been configured.
    defaultValue: 'http://localhost:3000/api',
  );

  /// Current environment name: "development", "staging", or "production".
  static const String environment = String.fromEnvironment(
    'DIRSHA_ENV',
    defaultValue: 'development',
  );

  // ---------------------------------------------------------------------------
  // Derived flags
  // ---------------------------------------------------------------------------

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  /// When true, the app uses mock repositories in place of live API calls.
  ///
  /// Mock mode is only active during development when the backend is not
  /// yet available.  It is explicitly configured — the app never silently
  /// falls back to mock data after a live network failure.
  static const bool useMockRepositories = bool.fromEnvironment(
    'DIRSHA_USE_MOCKS',
    defaultValue: true, // Default to mocks until API contract is confirmed
  );

  // ---------------------------------------------------------------------------
  // HTTP client settings
  // ---------------------------------------------------------------------------

  /// Default timeout for API requests.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // App metadata
  // ---------------------------------------------------------------------------

  static const String appName = 'Dirsha';
  static const String appVersion = '1.0.0';

  /// Phase label — used only in development UI labels and log messages.
  static const String buildPhase = 'Phase 1';
}
