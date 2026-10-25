import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dirsha_mobile/core/theme/app_theme.dart';
import 'package:dirsha_mobile/core/theme/theme_provider.dart';
import 'package:dirsha_mobile/features/auth/models/auth_models.dart';
import 'package:dirsha_mobile/features/auth/providers/auth_provider.dart';
import 'package:dirsha_mobile/features/auth/repositories/mock_auth_repository.dart';
import 'package:dirsha_mobile/features/portfolio/providers/portfolio_provider.dart';
import 'package:dirsha_mobile/features/portfolio/repositories/mock_portfolio_repository.dart';
import 'package:dirsha_mobile/features/profile/screens/profile_screen.dart';
import 'package:dirsha_mobile/features/subscriptions/providers/subscription_provider.dart';
import 'package:dirsha_mobile/features/subscriptions/repositories/mock_subscription_repository.dart';
import 'package:dirsha_mobile/features/wallet/providers/wallet_provider.dart';
import 'package:dirsha_mobile/features/wallet/repositories/mock_wallet_repository.dart';

Widget _buildTestableProfileScreen({
  required AuthProvider authProvider,
  required WalletProvider walletProvider,
  required PortfolioProvider portfolioProvider,
  required SubscriptionProvider subscriptionProvider,
  required ThemeProvider themeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
      ChangeNotifierProvider<PortfolioProvider>.value(value: portfolioProvider),
      ChangeNotifierProvider<SubscriptionProvider>.value(value: subscriptionProvider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  group('ProfileScreen widget tests', () {
    late MockAuthRepository mockAuthRepo;
    late AuthProvider authProvider;
    late WalletProvider walletProvider;
    late PortfolioProvider portfolioProvider;
    late SubscriptionProvider subscriptionProvider;
    late ThemeProvider themeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAuthRepo = MockAuthRepository();
      authProvider = AuthProvider(repository: mockAuthRepo);
      walletProvider = WalletProvider(repository: MockWalletRepository());
      portfolioProvider = PortfolioProvider(repository: MockPortfolioRepository());
      subscriptionProvider = SubscriptionProvider(repository: MockSubscriptionRepository());
      themeProvider = await ThemeProvider.create();

      // Sign in mock user
      await authProvider.login(
        const LoginRequest(email: 'investor@dirsha.dev', password: 'Demo1234!'),
      );
      await walletProvider.load();
    });

    testWidgets('renders user header with name, email, and role badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableProfileScreen(
          authProvider: authProvider,
          walletProvider: walletProvider,
          portfolioProvider: portfolioProvider,
          subscriptionProvider: subscriptionProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Abebe Girma'), findsWidgets);
      expect(find.text('investor@dirsha.dev'), findsWidgets);
      expect(find.text('INVESTOR'), findsWidgets);
      expect(find.text('Account & Profile'), findsOneWidget);
    });

    testWidgets('shows wallet and investment summary cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableProfileScreen(
          authProvider: authProvider,
          walletProvider: walletProvider,
          portfolioProvider: portfolioProvider,
          subscriptionProvider: subscriptionProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Financial Overview'), findsOneWidget);
      expect(find.text('Available Funds'), findsOneWidget);
      expect(find.text('Portfolio Value'), findsOneWidget);
    });

    testWidgets('shows profile details and settings card with sign out', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableProfileScreen(
          authProvider: authProvider,
          walletProvider: walletProvider,
          portfolioProvider: portfolioProvider,
          subscriptionProvider: subscriptionProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Settings & Security'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
