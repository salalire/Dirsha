/// Application configuration.
///
/// API base URL is read from a compile-time environment variable:
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000
///
/// If the variable is not set, it defaults to localhost:3000 for local
/// development. Never hardcode a production URL here.
abstract final class AppConfig {
  /// Backend API base URL.
  /// Set via --dart-define=API_BASE_URL=<url> at build/run time.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Application name shown in the UI.
  static const String appName = 'Dirsha Admin';

  /// Application version.
  static const String appVersion = '1.0.0-phase1';

  /// When true, the app uses mock repositories instead of real API calls.
  /// This is set to true by default for Phase 1 while the backend is in
  /// development. Set to false once backend endpoints are confirmed ready.
  ///
  /// IMPORTANT: This is a DEVELOPMENT convenience flag only.
  /// Backend authorization must protect every privileged operation.
  /// Disabling mock mode does not make the client "secure" on its own.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  /// Request timeout duration.
  static const Duration requestTimeout = Duration(seconds: 30);
}
