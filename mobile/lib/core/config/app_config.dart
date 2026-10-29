import 'package:flutter/foundation.dart';

/// Dirsha mobile application configuration.
abstract final class AppConfig {
  /// Backend URL. Can be overridden using --dart-define.
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'DIRSHA_API_BASE_URL',
    defaultValue: 'https://dirsha-1.onrender.com',
  );

  /// Base URL used by the HTTP client.
  static String get apiBaseUrl => _configuredApiBaseUrl;

  /// Current environment.
  static const String environment = String.fromEnvironment(
    'DIRSHA_ENV',
    defaultValue: 'production',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  /// Mock repositories are disabled by default.
  static const bool useMockRepositories = bool.fromEnvironment(
    'DIRSHA_USE_MOCKS',
    defaultValue: false,
  );

  /// HTTP client settings.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// App metadata.
  static const String appName = 'Dirsha';
  static const String appVersion = '1.0.0';
  static const String buildPhase = 'Phase 1';

  /// Deployed Company portal URL.
  static const String companyPortalUrl = String.fromEnvironment(
    'DIRSHA_COMPANY_PORTAL_URL',
    defaultValue: 'https://dirsha-company.onrender.com',
  );

  /// Deployed Broker portal URL.
  static const String brokerPortalUrl = String.fromEnvironment(
    'DIRSHA_BROKER_PORTAL_URL',
    defaultValue: 'https://dirsha-broker.onrender.com',
  );
}