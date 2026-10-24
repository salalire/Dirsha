import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/broker_portal_screen.dart';
import '../features/auth/screens/company_portal_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/ipos/providers/ipo_provider.dart';
import '../features/ipos/screens/ipo_detail_screen.dart';
import '../features/ipos/repositories/ipo_repository.dart';
import '../features/subscriptions/screens/my_subscriptions_screen.dart';
import '../features/subscriptions/screens/subscription_detail_screen.dart';
import '../shared/widgets/loading_indicator.dart';

/// Route name constants — use these instead of string literals in screens.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const roleSelection = '/register/role';
  static const register = '/register';
  static const companyPortal = '/register/company';
  static const brokerPortal = '/register/broker';
  static const home = '/home';
  static const ipoDetail = '/ipos/:id';
  static const subscriptions = '/subscriptions';
  static const subscriptionDetail = '/subscriptions/:id';

  /// Builds the ipoDetail path for a given [id].
  static String ipoDetailPath(String id) => '/ipos/$id';

  /// Builds the subscriptionDetail path for a given [id].
  static String subscriptionDetailPath(String id) => '/subscriptions/$id';
}

/// Builds the application router.
///
/// Authentication guard:
/// - If [AuthStatus] is [AuthStatus.unknown], show a splash/loading screen
///   while the startup check runs.
/// - If [AuthStatus.unauthenticated], redirect to /login from any protected
///   route.
/// - If [AuthStatus.authenticated], redirect away from /login and /register
///   to /home.
///
/// The router listens to [AuthProvider] via [refreshListenable] so it
/// automatically re-evaluates the redirect whenever auth state changes.
GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authProvider,
    debugLogDiagnostics: false, // Do not log route transitions in production.
    redirect: (BuildContext context, GoRouterState state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      // Still checking stored token — stay on splash.
      if (status == AuthStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuth = status == AuthStatus.authenticated;
      // All auth-entry routes that an authenticated user should be
      // redirected away from.
      final isAuthRoute =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.roleSelection ||
          location == AppRoutes.companyPortal ||
          location == AppRoutes.brokerPortal;

      // Authenticated user on splash or auth screens → go home.
      if (isAuth && (isAuthRoute || location == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      // Unauthenticated user on splash or trying to reach a protected route → login.
      if (!isAuth && (location == AppRoutes.splash || !isAuthRoute)) {
        return AppRoutes.login;
      }

      return null; // No redirect needed.
    },
    routes: [
      // ------------------------------------------------------------------
      // Splash — shown only while AuthStatus.unknown (startup check).
      // ------------------------------------------------------------------
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const _SplashScreen()),

      // ------------------------------------------------------------------
      // Authentication
      // ------------------------------------------------------------------
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),

      // Role selection — entry point from "Create account" on login screen.
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (_, _) => const RoleSelectionScreen(),
      ),

      // Investor registration — navigated to from role selection.
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),

      // Company portal entry — navigated to from role selection.
      GoRoute(
        path: AppRoutes.companyPortal,
        builder: (_, _) => const CompanyPortalScreen(),
      ),

      // Broker portal entry — navigated to from role selection.
      GoRoute(
        path: AppRoutes.brokerPortal,
        builder: (_, _) => const BrokerPortalScreen(),
      ),

      // ------------------------------------------------------------------
      // Main app shell — all tabs live inside HomeScreen.
      // ------------------------------------------------------------------
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),

      // ------------------------------------------------------------------
      // IPO detail — navigated to from any tab via context.push('/ipos/:id')
      // ------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.ipoDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // Provide a fresh IpoDetailProvider scoped to this route so that
          // navigating back and forward always reflects the correct IPO.
          return ChangeNotifierProvider(
            create: (ctx) =>
                IpoDetailProvider(repository: ctx.read<IpoRepository>()),
            child: IpoDetailScreen(ipoId: id),
          );
        },
      ),

      // ------------------------------------------------------------------
      // Subscriptions list — /subscriptions
      // ------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.subscriptions,
        builder: (_, _) => const MySubscriptionsScreen(),
      ),

      // ------------------------------------------------------------------
      // Subscription detail & allocation outcome — /subscriptions/:id
      // ------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.subscriptionDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SubscriptionDetailScreen(subscriptionId: id);
        },
      ),
    ],

    // ------------------------------------------------------------------
    // Global error page — shown when a route is not found.
    // ------------------------------------------------------------------
    errorBuilder: (_, state) => _RouteErrorScreen(error: state.error),
  );
}

// ---------------------------------------------------------------------------
// Splash screen — minimal, shown only during the token-validity check.
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingIndicator.fullScreen(message: 'Starting Dirsha…'),
    );
  }
}

// ---------------------------------------------------------------------------
// Route error screen
// ---------------------------------------------------------------------------

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48),
              const SizedBox(height: 16),
              const Text('This page does not exist.'),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Go to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
