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
import 'package:dirsha_admin/features/companies/models/company_application.dart';
import 'package:dirsha_admin/features/companies/repositories/api_company_repository.dart';
import 'package:dirsha_admin/features/brokers/models/broker_application.dart';
import 'package:dirsha_admin/features/brokers/repositories/api_broker_repository.dart';

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

  group('ApiCompanyRepository', () {
    test('getApplications parses backend companies list', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/companies') {
          return http.Response(
            json.encode({
              'data': [
                {
                  'id': 'cmp-100',
                  'name': 'Ethio Cement SC',
                  'registration_number': 'CR-998877',
                  'tin': '0011223344',
                  'sector': 'Manufacturing',
                  'authorized_rep_name': 'Abebe Regassa',
                  'authorized_rep_email': 'abebe@ethio-cement.et',
                  'status': 'submitted',
                  'submitted_at': '2026-10-22T10:00:00Z',
                  'documents': [
                    {
                      'id': 'doc-10',
                      'document_type': 'commercial_registration',
                      'original_filename': 'cr.pdf',
                      'review_status': 'pending',
                    }
                  ],
                }
              ],
              'pagination': {'total': 1, 'page': 1, 'limit': 20},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiCompanyRepository(apiClient: apiClient);

      final companies = await repo.getApplications();
      expect(companies, hasLength(1));
      final c = companies.first;
      expect(c.id, 'cmp-100');
      expect(c.companyName, 'Ethio Cement SC');
      expect(c.representativeName, 'Abebe Regassa');
      expect(c.representativeEmail, 'abebe@ethio-cement.et');
      expect(c.registrationNumber, 'CR-998877');
      expect(c.tin, '0011223344');
      expect(c.sector, 'Manufacturing');
      expect(c.status, CompanyApplicationStatus.pending);
      expect(c.documents, hasLength(1));
      expect(c.documents.first.documentType, 'commercial_registration');
    });

    test('approveApplication posts to /admin/companies/:id/approve', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/companies/cmp-100/approve' &&
            request.method == 'POST') {
          called = true;
          return http.Response(
            json.encode({'message': 'Company approved', 'data': {'id': 'cmp-100'}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiCompanyRepository(apiClient: apiClient);

      await repo.approveApplication('cmp-100', notes: 'All docs verified');
      expect(called, isTrue);
    });

    test('rejectApplication posts to /admin/companies/:id/reject with reason', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/companies/cmp-100/reject' &&
            request.method == 'POST') {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'Invalid TIN certificate');
          called = true;
          return http.Response(
            json.encode({'message': 'Company rejected', 'data': {'id': 'cmp-100'}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiCompanyRepository(apiClient: apiClient);

      await repo.rejectApplication('cmp-100', reason: 'Invalid TIN certificate');
      expect(called, isTrue);
    });

    test('requestAdditionalInfo posts to /admin/companies/:id/request-info', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/companies/cmp-100/request-info' &&
            request.method == 'POST') {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['message'], 'Please re-upload a clear TIN document');
          called = true;
          return http.Response(
            json.encode({'message': 'Info requested', 'data': {'id': 'cmp-100'}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiCompanyRepository(apiClient: apiClient);

      await repo.requestAdditionalInfo('cmp-100',
          message: 'Please re-upload a clear TIN document');
      expect(called, isTrue);
    });
  });

  group('ApiBrokerRepository', () {
    test('getApplications parses backend brokers list', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/brokers') {
          return http.Response(
            json.encode({
              'data': [
                {
                  'id': 'brk-200',
                  'applicant_name': 'Kassahun Desta',
                  'applicant_email': 'kassahun@desta-securities.et',
                  'broker_type': 'firm',
                  'firm_name': 'Desta Securities SC',
                  'license_number': 'ECMA-BRK-0099',
                  'license_authority': 'ECMA',
                  'jurisdiction': 'ET',
                  'license_expiry_date': '2028-01-01T00:00:00Z',
                  'is_license_expired': false,
                  'status': 'under_review',
                  'submitted_at': '2026-10-21T12:00:00Z',
                  'documents': [
                    {
                      'id': 'doc-20',
                      'document_type': 'broker_license',
                      'original_filename': 'license.pdf',
                      'review_status': 'approved',
                    }
                  ],
                }
              ],
              'pagination': {'total': 1, 'page': 1, 'limit': 20},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiBrokerRepository(apiClient: apiClient);

      final brokers = await repo.getApplications();
      expect(brokers, hasLength(1));
      final b = brokers.first;
      expect(b.id, 'brk-200');
      expect(b.applicantName, 'Kassahun Desta');
      expect(b.firmName, 'Desta Securities SC');
      expect(b.brokerType, 'firm');
      expect(b.licenseNumber, 'ECMA-BRK-0099');
      expect(b.isLicenseExpired, isFalse);
      expect(b.status, BrokerApplicationStatus.underReview);
      expect(b.documents, hasLength(1));
    });

    test('approveApplication posts to /admin/brokers/:id/approve', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/brokers/brk-200/approve' &&
            request.method == 'POST') {
          called = true;
          return http.Response(
            json.encode({'message': 'Broker approved', 'data': {'id': 'brk-200'}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiBrokerRepository(apiClient: apiClient);

      await repo.approveApplication('brk-200', notes: 'ECMA license verified');
      expect(called, isTrue);
    });

    test('rejectApplication posts to /admin/brokers/:id/reject with reason', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/brokers/brk-200/reject' &&
            request.method == 'POST') {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'License authority unverifiable');
          called = true;
          return http.Response(
            json.encode({'message': 'Broker rejected', 'data': {'id': 'brk-200'}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiBrokerRepository(apiClient: apiClient);

      await repo.rejectApplication('brk-200', reason: 'License authority unverifiable');
      expect(called, isTrue);
    });

    test('reviewDocument posts to /admin/documents/:id/review', () async {
      var called = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/admin/documents/doc-20/review' &&
            request.method == 'POST') {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['status'], 'approved');
          called = true;
          return http.Response(
            json.encode({'message': 'Document review updated'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiBrokerRepository(apiClient: apiClient);

      await repo.reviewDocument('doc-20', status: 'approved');
      expect(called, isTrue);
    });
  });
}
