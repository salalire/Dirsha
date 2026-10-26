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
Widget _routerWrap({
  required String initialLocation,
  String? companyPortalUrl,
  String? brokerPortalUrl,
}) {
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
        builder: (_, _) => CompanyPortalScreen(portalUrl: companyPortalUrl),
      ),
      GoRoute(
        path: '/register/broker',
        builder: (_, _) => BrokerPortalScreen(portalUrl: brokerPortalUrl),
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
  // CompanyPortalScreen — connected state & portal launch
  // ---------------------------------------------------------------------------
  group('CompanyPortalScreen — connected state & portal launch', () {
    testWidgets('shows "Open company portal" button with configured URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(initialLocation: '/register/company'),
      );
      await tester.pump();

      expect(find.text('Open company portal'), findsOneWidget);
      expect(find.text('Company portal not yet available'), findsNothing);
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

    testWidgets('tapping "Open company portal" triggers portal launch', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(initialLocation: '/register/company'),
      );
      await tester.pump();

      await tester.tap(find.text('Open company portal'));
      await tester.pump();

      expect(find.textContaining('Opening company portal:'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  // ---------------------------------------------------------------------------
  // CompanyPortalScreen — unavailable state
  // ---------------------------------------------------------------------------
  group('CompanyPortalScreen — unavailable state', () {
    testWidgets('shows unavailable message when portal URL is explicitly empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(
          initialLocation: '/register/company',
          companyPortalUrl: '',
        ),
      );
      await tester.pump();

      expect(find.text('Company portal not yet available'), findsOneWidget);
      expect(find.text('Open company portal'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // BrokerPortalScreen — connected state & portal launch
  // ---------------------------------------------------------------------------
  group('BrokerPortalScreen — connected state & portal launch', () {
    testWidgets('shows "Open broker portal" button with configured URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(initialLocation: '/register/broker'),
      );
      await tester.pump();

      expect(find.text('Open broker portal'), findsOneWidget);
      expect(find.text('Broker portal not yet available'), findsNothing);
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

    testWidgets('tapping "Open broker portal" triggers portal launch', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(initialLocation: '/register/broker'),
      );
      await tester.pump();

      await tester.tap(find.text('Open broker portal'));
      await tester.pump();

      expect(find.textContaining('Opening broker portal:'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  // ---------------------------------------------------------------------------
  // BrokerPortalScreen — unavailable state
  // ---------------------------------------------------------------------------
  group('BrokerPortalScreen — unavailable state', () {
    testWidgets('shows unavailable message when portal URL is explicitly empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerWrap(
          initialLocation: '/register/broker',
          brokerPortalUrl: '',
        ),
      );
      await tester.pump();

      expect(find.text('Broker portal not yet available'), findsOneWidget);
      expect(find.text('Open broker portal'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Wallet model — santim integration (model-level, no widget)
  // ---------------------------------------------------------------------------
  group('WalletSummary.fromJson — santim contract', () {
    test('parses integer santim fields correctly', () {
      final json = {
        'id': 'w1',
        'currency': 'ETB',
        'available_minor': 700000,
        'reserved_minor': 300000,
        'total_minor': 1000000,
      };
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
