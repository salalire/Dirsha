import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/repositories/live_auth_repository.dart';
import 'features/auth/repositories/mock_auth_repository.dart';
import 'features/ipos/providers/ipo_provider.dart';
import 'features/ipos/repositories/ipo_repository.dart';
import 'features/ipos/repositories/live_ipo_repository.dart';
import 'features/ipos/repositories/mock_ipo_repository.dart';
import 'features/wallet/providers/wallet_provider.dart';
import 'features/wallet/repositories/live_wallet_repository.dart';
import 'features/wallet/repositories/mock_wallet_repository.dart';
import 'features/wallet/repositories/wallet_repository.dart';
import 'router/app_router.dart';

/// Application entry point.
///
/// Initialises shared infrastructure (secure storage, API client) then
/// hands off to [DirshApp].
///
/// Repository selection:
/// - When [AppConfig.useMockRepositories] is true (default during Phase 1),
///   all repositories use in-memory mock data.
/// - When false, live repositories call the real backend via [ApiClient].
///
/// The switch is controlled at compile time via:
///   flutter run --dart-define=DIRSHA_USE_MOCKS=false
///
/// NEVER mix mock and live repositories in the same build accidentally.
/// The [MockDataBanner] widgets on each screen make the current state
/// visible so it cannot be silently mistaken for production.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for Phase 1.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Shared secure storage instance — tokens are stored here via AuthInterceptor.
  // AndroidOptions uses EncryptedSharedPreferences by default since v9.
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  // Build the app widget tree, deferring auth check to DirshApp.initState.
  runApp(DirshApp(storage: storage));
}

class DirshApp extends StatefulWidget {
  const DirshApp({super.key, required this.storage});

  final FlutterSecureStorage storage;

  @override
  State<DirshApp> createState() => _DirshAppState();
}

class _DirshAppState extends State<DirshApp> {
  // Repositories — built once, injected into providers.
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final IpoRepository _ipoRepository;
  late final WalletRepository _walletRepository;

  // Providers — kept here so they outlive individual routes.
  late final AuthProvider _authProvider;
  late final IpoListProvider _ipoListProvider;
  late final WalletProvider _walletProvider;

  // Router — built after auth provider is ready.
  late final _router = buildAppRouter(_authProvider);

  @override
  void initState() {
    super.initState();

    // Build API client with a callback that forces sign-out when the
    // token refresh fails mid-session.
    _apiClient = ApiClient(
      storage: widget.storage,
      onUnauthenticated: () => _authProvider.forceSignOut(),
    );

    // Select repository implementations based on compile-time flag.
    if (AppConfig.useMockRepositories) {
      _authRepository = MockAuthRepository();
      _ipoRepository = MockIpoRepository();
      _walletRepository = MockWalletRepository();
    } else {
      _authRepository = LiveAuthRepository(apiClient: _apiClient);
      _ipoRepository = LiveIpoRepository(apiClient: _apiClient);
      _walletRepository = LiveWalletRepository(apiClient: _apiClient);
    }

    _authProvider = AuthProvider(repository: _authRepository);
    _ipoListProvider = IpoListProvider(repository: _ipoRepository);
    _walletProvider = WalletProvider(repository: _walletRepository);

    // Check whether a stored token is still valid. The router redirect
    // waits for AuthStatus to leave 'unknown' before navigating.
    _authProvider.checkAuthStatus();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _ipoListProvider.dispose();
    _walletProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories — exposed so route-scoped providers (IpoDetailProvider)
        // can read them via context.read<IpoRepository>().
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<IpoRepository>.value(value: _ipoRepository),
        Provider<WalletRepository>.value(value: _walletRepository),

        // Feature providers — app-scoped.
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<IpoListProvider>.value(value: _ipoListProvider),
        ChangeNotifierProvider<WalletProvider>.value(value: _walletProvider),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.dark,
        // No light theme in Phase 1 — dark emerald is the default.
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        // Accessibility: enable bold text and text-scaling support.
        builder: (context, child) {
          return MediaQuery(
            // Clamp text scale to prevent extremely large text from
            // breaking financial figure layout. A max of 1.3× is a
            // reasonable accessibility compromise for a fintech app.
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(
                context,
              ).textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
