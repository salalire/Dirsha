/// Application configuration.
///
/// Production builds should provide API_BASE_URL using --dart-define.
/// Example:
/// flutter build web --release
///   --dart-define=API_BASE_URL=https://dirsha-1.onrender.com
///   --dart-define=USE_MOCK_DATA=false
///
/// The localhost default is for local development only.
abstract final class AppConfig {
  /// Backend API base URL.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Application name shown in the UI.
  static const String appName = 'Dirsha Admin';

  /// Application version.
  static const String appVersion = '1.0.0-phase1';

  /// Whether to use mock repositories instead of real API calls.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  /// Request timeout duration.
  static const Duration requestTimeout = Duration(seconds: 30);
}