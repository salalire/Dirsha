// ⚠️  DEVELOPMENT MOCK — NOT FOR PRODUCTION USE
//
// This is a placeholder authentication service used while the backend
// /auth/login endpoint is not yet available (Phase 1 prototype).
//
// IT DOES NOT PERFORM REAL AUTHENTICATION.
// It does not contact any server. It does not validate any credential
// against a real user database.
//
// Replace this with ApiAuthService once Member 2's auth endpoint is ready.
// The AdminAuthProvider will automatically use whichever service is injected.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_user.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  static const _sessionKey = 'mock_session_active';

  // ⚠️  DEMO CREDENTIALS — development only, no real password checking.
  // These exist solely so the Phase 1 UI can be navigated and tested.
  // In production, the backend validates credentials — the client never does.
  static const _demoEmail = 'admin@dirsha.dev';
  static const _demoPassword = 'demo1234';

  static const _mockUser = AdminUser(
    id: 'mock-admin-001',
    email: _demoEmail,
    displayName: 'Demo Admin',
    role: 'admin',
    accountStatus: 'active', // MOCK VALUE — dev only
  );

  @override
  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final cleanEmail = email.trim().toLowerCase();
    final isAllowedEmail = cleanEmail == 'admin@dirsha.dev' ||
        cleanEmail == 'demo@dirsha.dev' ||
        cleanEmail == 'investor@dirsha.dev' ||
        cleanEmail == 'company@dirsha.dev' ||
        cleanEmail == 'broker@dirsha.dev';
    final isAllowedPassword = password == 'demo1234' || password == 'Demo1234!';

    if (isAllowedEmail && isAllowedPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, true);
      return _mockUser;
    }

    throw Exception(
      'Invalid credentials. Please check your email and password.',
    );
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  @override
  Future<AdminUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(_sessionKey) ?? false;
    return active ? _mockUser : null;
  }
}
