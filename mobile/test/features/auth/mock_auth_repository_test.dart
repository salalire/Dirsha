import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/core/errors/app_exception.dart';
import 'package:dirsha_mobile/features/auth/models/auth_models.dart';
import 'package:dirsha_mobile/features/auth/repositories/mock_auth_repository.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() => repo = MockAuthRepository());

  group('MockAuthRepository.login', () {
    test('succeeds with correct mock credentials', () async {
      final result = await repo.login(
        const LoginRequest(email: 'investor@dirsha.dev', password: 'Demo1234!'),
      );
      expect(result.user.email, 'investor@dirsha.dev');
      expect(result.user.role, 'INVESTOR');
      expect(result.tokens.accessToken, isNotEmpty);
    });

    test('throws ApiException for wrong password', () async {
      await expectLater(
        repo.login(
          const LoginRequest(email: 'investor@dirsha.dev', password: 'wrong'),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException for unknown email', () async {
      await expectLater(
        repo.login(
          const LoginRequest(email: 'nobody@dirsha.dev', password: 'Demo1234!'),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('error code is INVALID_CREDENTIALS', () async {
      try {
        await repo.login(
          const LoginRequest(email: 'bad@bad.com', password: 'bad'),
        );
        fail('Expected ApiException');
      } on ApiException catch (e) {
        expect(e.errorCode, 'INVALID_CREDENTIALS');
        expect(e.statusCode, 401);
      }
    });
  });

  group('MockAuthRepository.register', () {
    test('succeeds with new email', () async {
      final result = await repo.register(
        const RegisterRequest(
          firstName: 'Sara',
          lastName: 'Tesfaye',
          email: 'sara@dirsha.dev',
          phone: '+251911000002',
          password: 'ValidPass1!',
        ),
      );
      expect(result.user.firstName, 'Sara');
      expect(result.user.role, 'INVESTOR');
    });

    test('throws ApiException for taken email', () async {
      await expectLater(
        repo.register(
          const RegisterRequest(
            firstName: 'X',
            lastName: 'Y',
            email: 'taken@dirsha.dev',
            phone: '+251911000003',
            password: 'ValidPass1!',
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('conflict error code is EMAIL_ALREADY_EXISTS', () async {
      try {
        await repo.register(
          const RegisterRequest(
            firstName: 'X',
            lastName: 'Y',
            email: 'taken@dirsha.dev',
            phone: '+251911000003',
            password: 'ValidPass1!',
          ),
        );
        fail('Expected ApiException');
      } on ApiException catch (e) {
        expect(e.errorCode, 'EMAIL_ALREADY_EXISTS');
        expect(e.statusCode, 409);
      }
    });
  });

  group('MockAuthRepository.logout', () {
    test('clears current user', () async {
      await repo.login(
        const LoginRequest(email: 'investor@dirsha.dev', password: 'Demo1234!'),
      );
      await repo.logout();
      await expectLater(
        repo.getCurrentUser(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('MockAuthRepository.getCurrentUser', () {
    test('returns user after login', () async {
      await repo.login(
        const LoginRequest(email: 'investor@dirsha.dev', password: 'Demo1234!'),
      );
      final user = await repo.getCurrentUser();
      expect(user.email, 'investor@dirsha.dev');
    });

    test('throws UnauthorizedException before login', () async {
      await expectLater(
        repo.getCurrentUser(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
