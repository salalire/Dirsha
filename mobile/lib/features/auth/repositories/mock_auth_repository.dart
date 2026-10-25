import '../../../core/errors/app_exception.dart';
import '../models/auth_models.dart';
import 'auth_repository.dart';

/// Development mock for [AuthRepository].
///
/// IMPORTANT: This repository simulates authentication for development only.
/// It must NOT be used in production builds.
/// It does NOT represent a successful connection to the real backend.
///
/// The mock banner [MockDataBanner] is shown on screens that use this
/// repository so the development state is always visible.
///
/// Mock credentials:
///   Email:    investor@dirsha.dev
///   Password: Demo1234!
///
/// Any other email/password combination returns an error so form validation
/// and error states can be exercised.
class MockAuthRepository implements AuthRepository {
  static const _mockEmail = 'investor@dirsha.dev';
  static const _mockPassword = 'Demo1234!';

  // Simulated delay to exercise loading states.
  static const _delay = Duration(milliseconds: 800);

  static const _mockUser = UserProfile(
    id: 'mock-user-001',
    firstName: 'Abebe',
    lastName: 'Girma',
    email: _mockEmail,
    phone: '+251911000001',
    role: 'INVESTOR',
    accountStatus: 'ACTIVE',
  );

  static const _mockTokens = AuthTokens(
    accessToken: 'mock-access-token',
    refreshToken: 'mock-refresh-token',
  );

  UserProfile? _currentUser;

  @override
  Future<AuthResult> login(LoginRequest request) async {
    await Future.delayed(_delay);

    if (request.email.trim().toLowerCase() != _mockEmail ||
        request.password != _mockPassword) {
      throw const ApiException(
        statusCode: 401,
        message: 'Incorrect email or password.',
        errorCode: 'INVALID_CREDENTIALS',
      );
    }

    _currentUser = _mockUser;
    return const AuthResult(tokens: _mockTokens, user: _mockUser);
  }

  @override
  Future<AuthResult> register(RegisterRequest request) async {
    await Future.delayed(_delay);

    // Simulate duplicate-email conflict for testing error states.
    if (request.email.trim().toLowerCase() == 'taken@dirsha.dev') {
      throw const ApiException(
        statusCode: 409,
        message: 'An account with this email address already exists.',
        errorCode: 'EMAIL_ALREADY_EXISTS',
      );
    }

    final newUser = UserProfile(
      id: 'mock-user-new',
      firstName: request.firstName,
      lastName: request.lastName,
      email: request.email,
      phone: request.phone,
      role: 'INVESTOR',
      accountStatus: 'ACTIVE',
    );

    _currentUser = newUser;
    return AuthResult(tokens: _mockTokens, user: newUser);
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  @override
  Future<UserProfile> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_currentUser == null) {
      throw const UnauthorizedException();
    }
    return _currentUser!;
  }

  @override
  Future<UserProfile> updateProfile({String? fullName, String? phone}) async {
    await Future.delayed(_delay);
    if (_currentUser == null) {
      throw const UnauthorizedException();
    }
    String firstName = _currentUser!.firstName;
    String lastName = _currentUser!.lastName;
    if (fullName != null && fullName.trim().isNotEmpty) {
      final trimmed = fullName.trim();
      if (trimmed.contains(' ')) {
        firstName = trimmed.split(' ').first;
        lastName = trimmed.substring(trimmed.indexOf(' ') + 1);
      } else {
        firstName = trimmed;
        lastName = '';
      }
    }
    _currentUser = _currentUser!.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone ?? _currentUser!.phone,
    );
    return _currentUser!;
  }
}
