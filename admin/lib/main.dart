import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';

import 'features/audit/providers/audit_provider.dart';
import 'features/audit/repositories/api_audit_repository.dart';
import 'features/audit/repositories/audit_repository.dart';
import 'features/audit/repositories/mock_audit_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/api_auth_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/mock_auth_service.dart';
import 'features/users/providers/users_provider.dart';
import 'features/users/repositories/api_user_repository.dart';
import 'features/users/repositories/mock_user_repository.dart';
import 'features/users/repositories/user_repository.dart';
import 'features/companies/providers/companies_provider.dart';
import 'features/companies/repositories/api_company_repository.dart';
import 'features/companies/repositories/company_repository.dart';
import 'features/companies/repositories/mock_company_repository.dart';
import 'features/brokers/providers/brokers_provider.dart';
import 'features/brokers/repositories/api_broker_repository.dart';
import 'features/brokers/repositories/broker_repository.dart';
import 'features/brokers/repositories/mock_broker_repository.dart';
import 'features/ipos/providers/ipos_provider.dart';
import 'features/ipos/repositories/api_ipo_repository.dart';
import 'features/ipos/repositories/ipo_repository.dart';
import 'features/ipos/repositories/mock_ipo_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ApiClient apiClient = ApiClient();
  final AuthService authService;
  final UserRepository userRepository;
  final CompanyRepository companyRepository;
  final BrokerRepository brokerRepository;
  final IpoRepository ipoRepository;
  final AuditRepository auditRepository;

  if (AppConfig.useMockData) {
    authService = MockAuthService();
    userRepository = MockUserRepository();
    companyRepository = MockCompanyRepository();
    brokerRepository = MockBrokerRepository();
    ipoRepository = MockIpoRepository();
    auditRepository = MockAuditRepository();
  } else {
    authService = ApiAuthService(apiClient: apiClient);
    userRepository = ApiUserRepository(apiClient: apiClient);
    companyRepository = ApiCompanyRepository(apiClient: apiClient);
    brokerRepository = ApiBrokerRepository(apiClient: apiClient);
    ipoRepository = ApiIpoRepository(apiClient: apiClient);
    auditRepository = ApiAuditRepository(apiClient: apiClient);
  }

  final authProvider = AdminAuthProvider(authService: authService);
  await authProvider.initialize();
  apiClient.onUnauthorized = () => authProvider.signOut();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AdminAuthProvider>.value(value: authProvider),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuditRepository>.value(value: auditRepository),
        ChangeNotifierProvider(
            create: (_) => UsersProvider(repository: userRepository)),
        ChangeNotifierProvider(
            create: (_) =>
                CompaniesProvider(repository: companyRepository)),
        ChangeNotifierProvider(
            create: (_) =>
                BrokersProvider(repository: brokerRepository)),
        ChangeNotifierProvider(
            create: (_) => IposProvider(repository: ipoRepository)),
        ChangeNotifierProvider(
            create: (_) => AuditProvider(repository: auditRepository)),
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
