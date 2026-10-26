import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dirsha_mobile/core/theme/app_colors.dart';
import 'package:dirsha_mobile/core/theme/app_text_styles.dart';
import 'package:dirsha_mobile/core/theme/app_theme.dart';
import 'package:dirsha_mobile/core/theme/theme_provider.dart';
import 'package:dirsha_mobile/features/auth/models/auth_models.dart';
import 'package:dirsha_mobile/features/auth/providers/auth_provider.dart';
import 'package:dirsha_mobile/features/auth/repositories/mock_auth_repository.dart';
import 'package:dirsha_mobile/features/home/screens/home_screen.dart';
import 'package:dirsha_mobile/features/ipos/providers/ipo_provider.dart';
import 'package:dirsha_mobile/features/ipos/repositories/mock_ipo_repository.dart';
import 'package:dirsha_mobile/features/ipos/screens/ipo_list_screen.dart';
import 'package:dirsha_mobile/features/portfolio/providers/portfolio_provider.dart';
import 'package:dirsha_mobile/features/portfolio/repositories/mock_portfolio_repository.dart';
import 'package:dirsha_mobile/features/portfolio/screens/portfolio_screen.dart';
import 'package:dirsha_mobile/features/profile/screens/profile_screen.dart';
import 'package:dirsha_mobile/features/subscriptions/providers/subscription_provider.dart';
import 'package:dirsha_mobile/features/subscriptions/repositories/mock_subscription_repository.dart';
import 'package:dirsha_mobile/features/trading/providers/trading_provider.dart';
import 'package:dirsha_mobile/features/trading/repositories/mock_trading_repository.dart';
import 'package:dirsha_mobile/features/trading/screens/trading_screen.dart';
import 'package:dirsha_mobile/features/wallet/providers/wallet_provider.dart';
import 'package:dirsha_mobile/features/wallet/repositories/mock_wallet_repository.dart';
import 'package:dirsha_mobile/shared/widgets/confirmation_dialog.dart';
import 'package:dirsha_mobile/shared/widgets/dirsha_button.dart';
import 'package:dirsha_mobile/shared/widgets/dirsha_text_field.dart';
import 'package:dirsha_mobile/shared/widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Theme Architecture & Default Theme Preservation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default theme is Dark Mode (ThemeMode.dark)', () async {
      final themeProvider = await ThemeProvider.create();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDark, isTrue);
    });

    test('AppTheme definitions configure light and dark color schemes properly', () {
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.backgroundPrimary);
      expect(AppTheme.dark.colorScheme.surface, AppColors.backgroundSecondary);
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
      expect(AppTheme.dark.bottomSheetTheme.backgroundColor, AppColors.backgroundSecondary);

      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.lightBackgroundPrimary);
      expect(AppTheme.light.colorScheme.surface, AppColors.lightBackgroundSecondary);
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      expect(AppTheme.light.bottomSheetTheme.backgroundColor, AppColors.lightBackgroundSecondary);
    });

    testWidgets('AppColors and AppTextStyles helpers resolve theme-aware values', (
      WidgetTester tester,
    ) async {
      late BuildContext darkCtx;
      late BuildContext lightCtx;

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: AppTheme.dark,
            child: Builder(
              builder: (ctx) {
                darkCtx = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(AppColors.isDark(darkCtx), isTrue);
      expect(AppColors.backgroundPrimaryOf(darkCtx), AppColors.backgroundPrimary);
      expect(AppColors.cardSurfaceOf(darkCtx), AppColors.cardSurface);
      expect(AppColors.textPrimaryOf(darkCtx), AppColors.textPrimary);
      expect(AppColors.textSecondaryOf(darkCtx), AppColors.textSecondary);
      expect(AppTextStyles.cardTitleOf(darkCtx).color, AppColors.textPrimary);

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: AppTheme.light,
            child: Builder(
              builder: (ctx) {
                lightCtx = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(AppColors.isDark(lightCtx), isFalse);
      expect(AppColors.backgroundPrimaryOf(lightCtx), AppColors.lightBackgroundPrimary);
      expect(AppColors.cardSurfaceOf(lightCtx), AppColors.lightCardSurface);
      expect(AppColors.textPrimaryOf(lightCtx), AppColors.lightTextPrimary);
      expect(AppColors.textSecondaryOf(lightCtx), AppColors.lightTextSecondary);
      expect(AppTextStyles.cardTitleOf(lightCtx).color, AppColors.lightTextPrimary);
    });
  });

  group('Light Mode UI Components & Contrast Verification', () {
    testWidgets('Scaffold automatically inherits light background in Light Mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          home: const Scaffold(
            body: Center(child: Text('Content Area')),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // scaffold.backgroundColor is null, meaning it inherits ThemeData.scaffoldBackgroundColor
      expect(scaffold.backgroundColor, isNull);

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, AppColors.lightBackgroundPrimary);
    });

    testWidgets('StatusBadge adapts colors with high contrast in Light and Dark modes', (
      WidgetTester tester,
    ) async {
      // 1. Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Theme(
            data: AppTheme.dark,
            child: Scaffold(
              body: StatusBadge.fromString('OPEN'),
            ),
          ),
        ),
      );

      final darkBadgeContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.byType(Container),
        ),
      );
      final darkBoxDec = darkBadgeContainer.decoration as BoxDecoration;
      expect(darkBoxDec.color, AppColors.successSurface);

      final darkText = tester.widget<Text>(find.text('OPEN'));
      expect(darkText.style?.color, AppColors.success);

      // 2. Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          home: Theme(
            data: AppTheme.light,
            child: Scaffold(
              body: StatusBadge.fromString('OPEN'),
            ),
          ),
        ),
      );

      final lightBadgeContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.byType(Container),
        ),
      );
      final lightBoxDec = lightBadgeContainer.decoration as BoxDecoration;
      expect(lightBoxDec.color, AppColors.lightSuccessSurface);

      final lightText = tester.widget<Text>(find.text('OPEN'));
      expect(lightText.style?.color, AppColors.lightSuccess);
    });

    testWidgets('Shared widgets (Buttons, TextFields, Dialogs) respect Light Mode', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController(text: 'Test user');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: Column(
              children: [
                DirshaTextField(
                  label: 'Full Name',
                  controller: controller,
                ),
                DirshaButton(
                  label: 'Save Profile',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('ConfirmationDialog renders with theme-aware colors in Light Mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  ctx,
                  title: 'Confirm Action',
                  message: 'Are you sure?',
                  confirmLabel: 'Confirm',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      final dialogElement = tester.element(find.byType(AlertDialog));
      expect(Theme.of(dialogElement).dialogTheme.backgroundColor, AppColors.lightCardSurface);
    });
  });

  group('Dynamic Theme Switching Integration', () {
    testWidgets('Toggling theme switches between Dark and Light mode seamlessly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = await ThemeProvider.create();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, theme, _) {
              return MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: theme.themeMode,
                home: Scaffold(
                  body: Builder(
                    builder: (innerCtx) {
                      return Column(
                        children: [
                          Text(
                            'Active Header',
                            style: AppTextStyles.cardTitleOf(innerCtx),
                          ),
                          Text(
                            'Secondary Info',
                            style: AppTextStyles.bodyMediumOf(innerCtx),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initially Dark Mode
      expect(themeProvider.isDark, isTrue);
      var headerText = tester.widget<Text>(find.text('Active Header'));
      expect(headerText.style?.color, AppColors.textPrimary);

      // Toggle to Light Mode
      await themeProvider.toggleTheme();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(themeProvider.isDark, isFalse);
      expect(themeProvider.themeMode, ThemeMode.light);
      headerText = tester.widget<Text>(find.text('Active Header'));
      expect(headerText.style?.color, AppColors.lightTextPrimary);

      // Toggle back to Dark Mode
      await themeProvider.toggleTheme();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(themeProvider.isDark, isTrue);
      expect(themeProvider.themeMode, ThemeMode.dark);
      headerText = tester.widget<Text>(find.text('Active Header'));
      expect(headerText.style?.color, AppColors.textPrimary);
    });
  });

  group('Major Investor Screens Render in Light Mode', () {
    late MockAuthRepository mockAuthRepo;
    late AuthProvider authProvider;
    late IpoListProvider ipoProvider;
    late WalletProvider walletProvider;
    late PortfolioProvider portfolioProvider;
    late SubscriptionProvider subscriptionProvider;
    late TradingProvider tradingProvider;
    late ThemeProvider themeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAuthRepo = MockAuthRepository();
      authProvider = AuthProvider(repository: mockAuthRepo);
      ipoProvider = IpoListProvider(repository: MockIpoRepository());
      walletProvider = WalletProvider(repository: MockWalletRepository());
      portfolioProvider = PortfolioProvider(repository: MockPortfolioRepository());
      subscriptionProvider = SubscriptionProvider(repository: MockSubscriptionRepository());
      tradingProvider = TradingProvider(repository: MockTradingRepository());
      themeProvider = await ThemeProvider.create();
      await themeProvider.setThemeMode(ThemeMode.light);

      await authProvider.login(
        const LoginRequest(email: 'investor@dirsha.dev', password: 'Demo1234!'),
      );
      await ipoProvider.load();
      await walletProvider.load();
      await portfolioProvider.load();
      await subscriptionProvider.loadSubscriptions();
      await tradingProvider.load();
    });

    Widget createTestApp(Widget home) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<IpoListProvider>.value(value: ipoProvider),
          ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ChangeNotifierProvider<PortfolioProvider>.value(value: portfolioProvider),
          ChangeNotifierProvider<SubscriptionProvider>.value(value: subscriptionProvider),
          ChangeNotifierProvider<TradingProvider>.value(value: tradingProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          home: home,
        ),
      );
    }

    testWidgets('HomeScreen renders cleanly in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets('IpoListScreen renders cleanly in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const IpoListScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(IpoListScreen), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets('PortfolioScreen renders cleanly in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const PortfolioScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PortfolioScreen), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets('TradingScreen renders cleanly in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const TradingScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TradingScreen), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets('ProfileScreen renders cleanly in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProfileScreen), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);
    });
  });
}
