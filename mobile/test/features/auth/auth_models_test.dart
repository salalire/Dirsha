import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/auth/models/auth_models.dart';

void main() {
  group('AuthTokens.fromJson', () {
    test('parses valid response', () {
      final json = {'accessToken': 'access-abc', 'refreshToken': 'refresh-xyz'};
      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'access-abc');
      expect(tokens.refreshToken, 'refresh-xyz');
    });

    test('parses when refreshToken is absent', () {
      final json = {'accessToken': 'access-abc'};
      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'access-abc');
      expect(tokens.refreshToken, isNull);
    });

    test('throws FormatException when accessToken missing', () {
      expect(() => AuthTokens.fromJson({}), throwsA(isA<FormatException>()));
    });

    test('toString never contains token value', () {
      final tokens = AuthTokens.fromJson({'accessToken': 'secret-token-value'});
      expect(tokens.toString(), isNot(contains('secret-token-value')));
    });
  });

  group('UserProfile.fromJson', () {
    final validJson = {
      'id': 'user-1',
      'firstName': 'Abebe',
      'lastName': 'Girma',
      'email': 'abebe@example.com',
      'phone': '+251911000001',
      'role': 'INVESTOR',
      'accountStatus': 'ACTIVE',
    };

    test('parses all fields', () {
      final profile = UserProfile.fromJson(validJson);
      expect(profile.id, 'user-1');
      expect(profile.firstName, 'Abebe');
      expect(profile.lastName, 'Girma');
      expect(profile.email, 'abebe@example.com');
      expect(profile.role, 'INVESTOR');
      expect(profile.accountStatus, 'ACTIVE');
    });

    test('fullName concatenates first and last', () {
      final profile = UserProfile.fromJson(validJson);
      expect(profile.fullName, 'Abebe Girma');
    });

    test('isActive returns true for ACTIVE status', () {
      final profile = UserProfile.fromJson(validJson);
      expect(profile.isActive, isTrue);
    });

    test('isActive returns false for SUSPENDED status', () {
      final profile = UserProfile.fromJson({
        ...validJson,
        'accountStatus': 'SUSPENDED',
      });
      expect(profile.isActive, isFalse);
    });

    test('defaults role to INVESTOR when absent', () {
      final json = Map<String, dynamic>.from(validJson)..remove('role');
      final profile = UserProfile.fromJson(json);
      expect(profile.role, 'INVESTOR');
    });
  });

  group('AuthResult.fromJson', () {
    test('parses tokens and user together', () {
      final json = {
        'accessToken': 'tok-123',
        'refreshToken': 'ref-456',
        'user': {
          'id': 'u1',
          'firstName': 'Test',
          'lastName': 'User',
          'email': 'test@dirsha.dev',
          'phone': '+251911000000',
          'role': 'INVESTOR',
          'accountStatus': 'ACTIVE',
        },
      };
      final result = AuthResult.fromJson(json);
      expect(result.tokens.accessToken, 'tok-123');
      expect(result.user.email, 'test@dirsha.dev');
    });

    test('parses backend login response envelope with snake_case fields', () {
      final backendJson = {
        'data': {
          'access_token': 'jwt-backend-token-123',
          'token_type': 'Bearer',
          'expires_in': 900,
          'user': {
            'id': 'u-backend-1',
            'email': 'investor@dirsha.test',
            'full_name': 'Abebe Kebede',
            'phone': '+251 911 000 000',
            'role': 'investor',
            'account_status': 'active',
            'verification_status': 'unverified',
            'created_at': '2026-10-20T18:36:40.489Z',
          },
        },
      };
      final result = AuthResult.fromJson(backendJson);
      expect(result.tokens.accessToken, 'jwt-backend-token-123');
      expect(result.tokens.refreshToken, isNull);
      expect(result.user.id, 'u-backend-1');
      expect(result.user.firstName, 'Abebe');
      expect(result.user.lastName, 'Kebede');
      expect(result.user.fullName, 'Abebe Kebede');
      expect(result.user.role, 'INVESTOR');
      expect(result.user.accountStatus, 'ACTIVE');
      expect(result.user.isActive, isTrue);
    });
  });

  group('RegisterRequest.toJson', () {
    test('produces backend-compatible payload with full_name and role', () {
      const request = RegisterRequest(
        firstName: 'Dawit',
        lastName: 'Alemu',
        email: 'dawit@example.com',
        phone: '+251911223344',
        password: 'Password123!',
        role: 'investor',
      );
      final json = request.toJson();
      expect(json['full_name'], 'Dawit Alemu');
      expect(json['email'], 'dawit@example.com');
      expect(json['phone'], '+251911223344');
      expect(json['role'], 'investor');
      expect(json.containsKey('firstName'), isFalse);
      expect(json.containsKey('lastName'), isFalse);
    });
  });
}
