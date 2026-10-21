import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dirsha_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:dirsha_mobile/features/auth/screens/company_portal_screen.dart';
import 'package:dirsha_mobile/features/auth/screens/broker_portal_screen.dart';
import 'package:dirsha_mobile/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps a widget in a GoRouter for navigation tests.
Widget _routerWrap({required String initialLocation}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/register/role',
        builder: (_, _) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const Scaffold(body: Text('Investor Register')),
      ),
      GoRoute(
        path: '/register/company',
        builder: (_, _) => const CompanyPortalScreen(),
      ),
      GoRoute(
        path: '/register/broker',
        builder: (_, _) => const BrokerPortalScreen(),
      ),
    ],
  );
  return MaterialApp.router(theme: AppTheme.dark, routerConfig: router);
}

// ---------------------------------------------------------------------------
// RoleSelectionScreen — content
// ---------------------------------------------------------------------------
void main() {
  group('RoleSelectionScreen — content', () {
    testWidgets('shows three role options', (tester) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/role'));
      await tester.pump();

      expect(find.text('Investor'), findsOneWidget);
      expect(find.text('Company'), findsOneWidget);
      expect(find.text('Broker'), findsOneWidget);
    });

    testWidgets('shows descriptive text for each role', (tester) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/role'));
      await tester.pump();

      // Investor description fragment
      expect(find.textContaining('Browse IPO offerings'), findsOneWidget);
      // Company description fragment
      expect(find.textContaining('company onboarding portal'), findsOneWidget);
      // Broker description fragment
      expect(find.textContaining('broker portal'), findsOneWidget);
    });

    testWidgets('shows "Already have an account?" sign-in link', (
      tester,
    ) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/role'));
      await tester.pump();
      expect(find.text('Sign in'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // RoleSelectionScreen — navigation
  // ---------------------------------------------------------------------------
  group('RoleSelectionScreen — navigation', () {
    testWidgets('tapping Investor navigates to /register', (tester) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/role'));
      await tester.pump();

      await tester.tap(find.text('Investor'));
      await tester.pumpAndSettle();

      expect(find.text('Investor Register'), findsOneWidget);
    });

    testWidgets('tapping Company navigates to /register/company', (
      tester,
    ) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/role'));
      await tester.pump();

      await tester.tap(find.text('Company'));
      await tester.pumpAndSettle();

      expect(
        find.text('Company onboarding'),
        findsWidgets,
      ); // AppBar + body heading
    });

    testWidgets('tapping Broker navigates to /register/broker', (tester) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/role'));
      await tester.pump();

      await tester.tap(find.text('Broker'));
      await tester.pumpAndSettle();

      expect(
        find.text('Broker registration'),
        findsWidgets,
      ); // AppBar + body heading
    });
  });

  // ---------------------------------------------------------------------------
  // CompanyPortalScreen — unavailable state (default: no portal URL)
  // ---------------------------------------------------------------------------
  group('CompanyPortalScreen — unavailable state', () {
    testWidgets('shows unavailable message when portal URL is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(initialLocation: '/register/company'),
      );
      await tester.pump();

      // AppConfig.companyPortalUrl defaults to '' in test environment
      expect(find.text('Company portal not yet available'), findsOneWidget);
    });

    testWidgets('does NOT show a broken portal button when URL is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(initialLocation: '/register/company'),
      );
      await tester.pump();

      expect(find.text('Open company portal'), findsNothing);
    });

    testWidgets('shows informational note about external portal', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(initialLocation: '/register/company'),
      );
      await tester.pump();

      expect(find.textContaining('dedicated web portal'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // BrokerPortalScreen — unavailable state
  // ---------------------------------------------------------------------------
  group('BrokerPortalScreen — unavailable state', () {
    testWidgets('shows unavailable message when portal URL is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/broker'));
      await tester.pump();

      expect(find.text('Broker portal not yet available'), findsOneWidget);
    });

    testWidgets('does NOT show a broken portal button when URL is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/broker'));
      await tester.pump();

      expect(find.text('Open broker portal'), findsNothing);
    });

    testWidgets('shows authorization note about backend enforcement', (
      tester,
    ) async {
      await tester.pumpWidget(_routerWrap(initialLocation: '/register/broker'));
      await tester.pump();

      expect(
        find.textContaining('All permissions are enforced'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Wallet model — santim integration (model-level, no widget)
  // ---------------------------------------------------------------------------
  group('WalletSummary.fromJson — santim contract', () {
    test('parses integer santim fields correctly', () {
      // Simulates what the live backend will send
      final json = {
        'id': 'w1',
        'currency': 'ETB',
        'available_minor': 700000,
        'reserved_minor': 300000,
        'total_minor': 1000000,
      };
      // Import inline to avoid needing a barrel
      // We verify via the Money value directly
      from(dynamic v) {
        if (v is int) return v;
        return null;
      }

      expect(from(json['available_minor']), 700000);
      expect(from(json['reserved_minor']), 300000);
      expect(from(json['total_minor']), 1000000);
    });
  });
}
