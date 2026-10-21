import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/mock_auth_service.dart';
import 'features/users/providers/users_provider.dart';
import 'features/users/repositories/mock_user_repository.dart';
import 'features/companies/providers/companies_provider.dart';
import 'features/companies/repositories/mock_company_repository.dart';
import 'features/ipos/providers/ipos_provider.dart';
import 'features/ipos/repositories/mock_ipo_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = MockAuthService();
  final authProvider = AdminAuthProvider(authService: authService);
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AdminAuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(
            create: (_) => UsersProvider(repository: MockUserRepository())),
        ChangeNotifierProvider(
            create: (_) =>
                CompaniesProvider(repository: MockCompanyRepository())),
        ChangeNotifierProvider(
            create: (_) => IposProvider(repository: MockIpoRepository())),
      ],
      child: DirshaAdminApp(authProvider: authProvider),
    ),
  );
}

class DirshaAdminApp extends StatefulWidget {
  const DirshaAdminApp({super.key, required this.authProvider});
  final AdminAuthProvider authProvider;

  @override
  State<DirshaAdminApp> createState() => _DirshaAdminAppState();
}

class _DirshaAdminAppState extends State<DirshaAdminApp> {
  late final router = createRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp.router(
      title: 'Dirsha Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
