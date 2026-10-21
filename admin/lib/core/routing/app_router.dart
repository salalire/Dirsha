import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/users/screens/users_list_screen.dart';
import '../../features/users/screens/user_detail_screen.dart';
import '../../features/companies/screens/companies_list_screen.dart';
import '../../features/companies/screens/company_detail_screen.dart';
import '../../features/ipos/screens/ipos_list_screen.dart';
import '../../features/ipos/screens/ipo_detail_screen.dart';
import '../../features/audit/screens/audit_screen.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

/// Creates the GoRouter with authentication-aware redirect logic.
///
/// Route guard: if a user is not signed in, they are redirected to sign-in.
/// This is a UI convenience only — the backend enforces real authorization.
GoRouter createRouter(AdminAuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isSignedIn = authProvider.isSignedIn;
      final isLoading = authProvider.isLoading;
      final isSignInRoute = state.matchedLocation == AppRoutes.signIn;

      if (isLoading) return null;
      if (!isSignedIn && !isSignInRoute) return AppRoutes.signIn;
      if (isSignedIn && isSignInRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      // ── Public ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),

      // ── Authenticated shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.userReviews,
            builder: (context, state) => const UsersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    UserDetailScreen(userId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.companyReviews,
            builder: (context, state) => const CompaniesListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CompanyDetailScreen(
                    companyId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.ipoManagement,
            builder: (context, state) => const IposListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    IpoDetailScreen(ipoId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.audit,
            builder: (context, state) => const AuditScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFB91C1C)),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
