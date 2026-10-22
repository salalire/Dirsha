import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dirsha_admin/core/network/api_client.dart';
import 'package:dirsha_admin/features/auth/services/api_auth_service.dart';
import 'package:dirsha_admin/features/ipos/models/ipo_application.dart';
import 'package:dirsha_admin/features/ipos/repositories/api_ipo_repository.dart';
import 'package:dirsha_admin/features/users/models/user_application.dart';
import 'package:dirsha_admin/features/users/repositories/api_user_repository.dart';
import 'package:dirsha_admin/features/audit/repositories/api_audit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiAuthService', () {
    test('signIn succeeds and sets token on ApiClient', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/auth/login') {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'admin@dirsha.test');
          expect(body['password'], 'secret123');

          return http.Response(
            json.encode({
              'data': {
                'access_token': 'test-admin-jwt-token',
                'token_type': 'Bearer',
                'expires_in': 900,
                'user': {
                  'id': 'admin-uuid-1',
                  'email': 'admin@dirsha.test',
                  'full_name': 'Admin User',
                  'role': 'admin',
                  'account_status': 'active',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final authService = ApiAuthService(apiClient: apiClient);

      final user = await authService.signIn(
        email: 'admin@dirsha.test',
        password: 'secret123',
      );

      expect(user.id, 'admin-uuid-1');
      expect(user.email, 'admin@dirsha.test');
      expect(user.displayName, 'Admin User');
      expect(user.role, 'admin');
      expect(user.isActive, isTrue);
      expect(apiClient.hasToken, isTrue);

      // Verify session restored via getCurrentUser
      final restored = await authService.getCurrentUser();
      expect(restored?.id, 'admin-uuid-1');

      // Sign out
      await authService.signOut();
      expect(apiClient.hasToken, isFalse);
      expect(await authService.getCurrentUser(), isNull);
    });
  });

  group('ApiIpoRepository', () {
    test('getApplications parses backend snake_case IPOs', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/ipos') {
          return http.Response(
            json.encode({
              'data': [
                {
                  'id': 'ipo-1',
                  'company_id': 'comp-1',
                  'company_name': 'Ethio Telecom',
                  'title': 'Ethio Telecom IPO',
                  'symbol': 'ETEL',
                  'status': 'open',
                  'price_per_share_minor': 10000,
                  'total_shares': 500000,
                  'opens_at': '2026-10-20T00:00:00Z',
                  'closes_at': '2026-10-30T00:00:00Z',
                  'created_at': '2026-10-15T00:00:00Z',
                }
              ],
              'pagination': {'total': 1, 'page': 1, 'page_size': 20},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiIpoRepository(apiClient: apiClient);

      final ipos = await repo.getApplications();
      expect(ipos, hasLength(1));
      final ipo = ipos.first;
      expect(ipo.id, 'ipo-1');
      expect(ipo.companyName, 'Ethio Telecom');
      expect(ipo.offeringTitle, 'Ethio Telecom IPO');
      expect(ipo.status, IpoStatus.open);
      expect(ipo.pricePerShareSantim, 10000);
      expect(ipo.totalSharesOffered, 500000);
    });

    test('approveApplication posts to /admin/ipos/:id/approve', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/ipos/ipo-1/approve' && request.method == 'POST') {
          called = true;
          return http.Response(
            json.encode({'id': 'ipo-1', 'status': 'approved'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiIpoRepository(apiClient: apiClient);

      await repo.approveApplication('ipo-1', notes: 'Approved for public listing');
      expect(called, isTrue);
    });

    test('rejectApplication posts to /admin/ipos/:id/reject', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/ipos/ipo-1/reject' && request.method == 'POST') {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'Missing audit financials');
          called = true;
          return http.Response(
            json.encode({'id': 'ipo-1', 'status': 'rejected'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiIpoRepository(apiClient: apiClient);

      await repo.rejectApplication('ipo-1', reason: 'Missing audit financials');
      expect(called, isTrue);
    });
  });

  group('ApiUserRepository', () {
    test('getApplications parses backend snake_case users', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/users') {
          return http.Response(
            json.encode({
              'data': [
                {
                  'id': 'usr-1',
                  'email': 'investor@dirsha.test',
                  'full_name': 'Abebe Kebede',
                  'role': 'investor',
                  'account_status': 'active',
                  'verification_status': 'verified',
                  'created_at': '2026-10-21T10:00:00Z',
                }
              ],
              'pagination': {'total': 1, 'page': 1, 'page_size': 20},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiUserRepository(apiClient: apiClient);

      final users = await repo.getApplications();
      expect(users, hasLength(1));
      final u = users.first;
      expect(u.id, 'usr-1');
      expect(u.displayName, 'Abebe Kebede');
      expect(u.email, 'investor@dirsha.test');
      expect(u.role, UserRole.investor);
      expect(u.accountStatus, UserAccountStatus.active);
      expect(u.verificationStatus, UserVerificationStatus.verified);
    });
  });

  group('ApiAuditRepository', () {
    test('getRecentEvents parses backend snake_case audit events', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/audit') {
          return http.Response(
            json.encode({
              'data': [
                {
                  'id': 'aud-1',
                  'actor_user_id': 'admin-uuid-1',
                  'actor_role': 'admin',
                  'action': 'ipo.approve',
                  'target_type': 'ipo',
                  'target_id': 'ipo-1',
                  'outcome': 'success',
                  'request_id': 'req-12345',
                  'created_at': '2026-10-22T08:00:00Z',
                }
              ],
              'pagination': {'total': 1, 'page': 1, 'page_size': 50},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiAuditRepository(apiClient: apiClient);

      final events = await repo.getRecentEvents();
      expect(events, hasLength(1));
      final ev = events.first;
      expect(ev.id, 'aud-1');
      expect(ev.actorId, 'admin-uuid-1');
      expect(ev.actorRole, 'admin');
      expect(ev.action, 'ipo.approve');
      expect(ev.targetResource, 'ipo:ipo-1');
      expect(ev.outcome, 'success');
      expect(ev.referenceId, 'req-12345');
    });
  });
}
