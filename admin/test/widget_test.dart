// Basic smoke test — verifies that the app widget tree builds without errors.
// Full integration tests will be added in Phase 2 once the backend is available.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dirsha_admin/main.dart';
import 'package:dirsha_admin/features/auth/providers/auth_provider.dart';
import 'package:dirsha_admin/features/auth/services/mock_auth_service.dart';
import 'package:dirsha_admin/features/users/providers/users_provider.dart';
import 'package:dirsha_admin/features/users/repositories/mock_user_repository.dart';
import 'package:dirsha_admin/features/companies/providers/companies_provider.dart';
import 'package:dirsha_admin/features/companies/repositories/mock_company_repository.dart';
import 'package:dirsha_admin/features/ipos/providers/ipos_provider.dart';
import 'package:dirsha_admin/features/ipos/repositories/mock_ipo_repository.dart';

void main() {
  testWidgets('App builds without runtime errors', (tester) async {
    final authProvider = AdminAuthProvider(
      authService: MockAuthService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminAuthProvider>.value(
              value: authProvider),
          ChangeNotifierProvider(
              create: (_) =>
                  UsersProvider(repository: MockUserRepository())),
          ChangeNotifierProvider(
              create: (_) =>
                  CompaniesProvider(repository: MockCompanyRepository())),
          ChangeNotifierProvider(
              create: (_) =>
                  IposProvider(repository: MockIpoRepository())),
        ],
        child: DirshaAdminApp(authProvider: authProvider),
      ),
    );

    // The app should render without throwing
    expect(find.byType(MaterialApp), findsNothing); // Uses MaterialApp.router
    expect(find.byType(Router), findsOneWidget);
  });
}
