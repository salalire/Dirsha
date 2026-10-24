import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/repositories/live_auth_repository.dart';
import 'features/auth/repositories/mock_auth_repository.dart';
import 'features/ipos/providers/ipo_provider.dart';
import 'features/ipos/repositories/ipo_repository.dart';
import 'features/ipos/repositories/live_ipo_repository.dart';
import 'features/ipos/repositories/mock_ipo_repository.dart';
import 'features/portfolio/providers/portfolio_provider.dart';
import 'features/portfolio/repositories/live_portfolio_repository.dart';
import 'features/portfolio/repositories/mock_portfolio_repository.dart';
import 'features/portfolio/repositories/portfolio_repository.dart';
import 'features/subscriptions/providers/subscription_provider.dart';
import 'features/subscriptions/repositories/live_subscription_repository.dart';
import 'features/subscriptions/repositories/mock_subscription_repository.dart';
import 'features/subscriptions/repositories/subscription_repository.dart';
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

  // Load persisted theme preference before the first frame so there
  // is no flash of the wrong theme on startup.
  final themeProvider = await ThemeProvider.create();

  // Shared secure storage instance — tokens are stored here via AuthInterceptor.
  // AndroidOptions uses EncryptedSharedPreferences by default since v9.
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  runApp(DirshApp(storage: storage, themeProvider: themeProvider));
}

class DirshApp extends StatefulWidget {
  const DirshApp({
    super.key,
    required this.storage,
    required this.themeProvider,
  });

  final FlutterSecureStorage storage;
  final ThemeProvider themeProvider;

  @override
  State<DirshApp> createState() => _DirshAppState();
}

class _DirshAppState extends State<DirshApp> {
  // Repositories — built once, injected into providers.
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final IpoRepository _ipoRepository;
  late final WalletRepository _walletRepository;
  late final SubscriptionRepository _subscriptionRepository;
  late final PortfolioRepository _portfolioRepository;

  // Providers — kept here so they outlive individual routes.
  late final AuthProvider _authProvider;
  late final IpoListProvider _ipoListProvider;
  late final WalletProvider _walletProvider;
  late final SubscriptionProvider _subscriptionProvider;
  late final PortfolioProvider _portfolioProvider;

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
      _subscriptionRepository =
          MockSubscriptionRepository(walletRepository: _walletRepository);
      _portfolioRepository = MockPortfolioRepository();
    } else {
      _authRepository = LiveAuthRepository(apiClient: _apiClient);
      _ipoRepository = LiveIpoRepository(apiClient: _apiClient);
      _walletRepository = LiveWalletRepository(apiClient: _apiClient);
      _subscriptionRepository =
          LiveSubscriptionRepository(apiClient: _apiClient);
      _portfolioRepository = LivePortfolioRepository(apiClient: _apiClient);
    }

    _authProvider = AuthProvider(repository: _authRepository);
    _ipoListProvider = IpoListProvider(repository: _ipoRepository);
    _walletProvider = WalletProvider(repository: _walletRepository);
    _subscriptionProvider =
        SubscriptionProvider(repository: _subscriptionRepository);
    _portfolioProvider = PortfolioProvider(repository: _portfolioRepository);

    // Check whether a stored token is still valid. The router redirect
    // waits for AuthStatus to leave 'unknown' before navigating.
    _authProvider.checkAuthStatus();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _ipoListProvider.dispose();
    _walletProvider.dispose();
    _subscriptionProvider.dispose();
    _portfolioProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme — app-scoped, must be above MaterialApp so it can drive themeMode.
        ChangeNotifierProvider<ThemeProvider>.value(
          value: widget.themeProvider,
        ),

        // Repositories — exposed so route-scoped providers (IpoDetailProvider)
        // can read them via context.read<IpoRepository>().
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<IpoRepository>.value(value: _ipoRepository),
        Provider<WalletRepository>.value(value: _walletRepository),
        Provider<SubscriptionRepository>.value(value: _subscriptionRepository),
        Provider<PortfolioRepository>.value(value: _portfolioRepository),

        // Feature providers — app-scoped.
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<IpoListProvider>.value(value: _ipoListProvider),
        ChangeNotifierProvider<WalletProvider>.value(value: _walletProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(
          value: _subscriptionProvider,
        ),
        ChangeNotifierProvider<PortfolioProvider>.value(
          value: _portfolioProvider,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          title: AppConfig.appName,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          // Controlled by the user's in-app preference, persisted across
          // restarts. Dark is the default until the user changes it.
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(
                  context,
                ).textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
              ),
              child: child!,
            );
          },
        ),
      ),
    );
  }
}
