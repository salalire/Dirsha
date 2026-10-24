import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:dirsha_admin/core/network/api_client.dart';
import 'package:dirsha_admin/features/subscriptions/models/subscription_model.dart';
import 'package:dirsha_admin/features/subscriptions/providers/subscriptions_provider.dart';
import 'package:dirsha_admin/features/subscriptions/repositories/api_subscription_repository.dart';
import 'package:dirsha_admin/features/subscriptions/repositories/mock_subscription_repository.dart';
import 'package:dirsha_admin/features/subscriptions/repositories/subscription_repository.dart';
import 'package:dirsha_admin/features/subscriptions/screens/subscriptions_list_screen.dart';

void main() {
  group('AdminSubscription Model & Calculations', () {
    test('parses JSON and computes financial figures and allocation states correctly', () {
      final jsonMap = {
        'id': 'sub-test-101',
        'ipo_id': 'ipo-ethio-telecom-001',
        'ipo_title': 'Ethio Telecom Class A Shares',
        'ipo_symbol': 'ETHTEL',
        'company_name': 'Ethio Telecom SC',
        'investor_id': 'usr-inv-001',
        'investor_name': 'Abebe Bikila',
        'investor_email': 'abebe.bikila@example.com',
        'quantity': 100,
        'price_per_share_minor': 30000,
        'total_amount_minor': 3000000,
        'allocated_quantity': 40,
        'status': 'settled',
        'idempotency_key': 'idem-test-101',
        'created_at': '2026-03-24T10:00:00Z',
        'allocated_at': '2026-03-25T14:00:00Z',
      };

      final sub = AdminSubscription.fromJson(jsonMap);

      expect(sub.id, 'sub-test-101');
      expect(sub.status, AdminSubscriptionStatus.settled);
      expect(sub.quantity, 100);
      expect(sub.allocatedQuantity, 40);
      expect(sub.isSettled, isTrue);
      expect(sub.isPartial, isTrue);
      expect(sub.isFull, isFalse);
      expect(sub.isZero, isFalse);
      expect(sub.sharePriceEtb, 300.0);
      expect(sub.totalAmountEtb, 30000.0);
      expect(sub.allocatedAmountMinor, 1200000); // 40 * 30000
      expect(sub.allocatedAmountEtb, 12000.0);
      expect(sub.unallocatedQuantity, 60);
      expect(sub.unallocatedRefundMinor, 1800000); // 60 * 30000
      expect(sub.unallocatedRefundEtb, 18000.0);
    });

    test('correctly handles reserved pending subscription', () {
      final jsonMap = {
        'id': 'sub-test-102',
        'ipo_id': 'ipo-awash-bank-002',
        'ipo_title': 'Awash Bank Expansion 2026',
        'ipo_symbol': 'AWASH',
        'company_name': 'Awash International Bank SC',
        'investor_id': 'usr-inv-002',
        'investor_name': 'Almaz Ayana',
        'investor_email': 'almaz@example.com',
        'quantity': 25,
        'price_per_share_minor': 50000,
        'total_amount_minor': 1250000,
        'allocated_quantity': 0,
        'status': 'reserved',
        'idempotency_key': 'idem-test-102',
        'created_at': '2026-03-24T10:00:00Z',
      };

      final sub = AdminSubscription.fromJson(jsonMap);
      expect(sub.isReserved, isTrue);
      expect(sub.isSettled, isFalse);
      expect(sub.allocatedQuantity, 0);
    });
  });

  group('SubscriptionsProvider & MockRepository', () {
    late MockSubscriptionsRepository repository;
    late SubscriptionsProvider provider;

    setUp(() {
      repository = MockSubscriptionsRepository();
      provider = SubscriptionsProvider(repository: repository);
    });

    test('loadSubscriptions retrieves seeded list and aggregates metrics', () async {
      await provider.loadSubscriptions();

      expect(provider.isLoading, isFalse);
      expect(provider.subscriptions.length, 4);
      expect(provider.totalSubscriptions, 4);
      expect(provider.totalRequestedShares, 185); // 25 + 50 + 100 + 10
      expect(provider.totalAllocatedShares, 90); // 50 + 40
      expect(provider.totalCommittedValueMinor, 5750000); // 750k + 1.5m + 3m + 500k
      expect(provider.errorMessage, isNull);

      // Oversubscription ratio calculation
      final ratio = provider.oversubscriptionRatio(100);
      expect(ratio, 185.0); // 185 requested / 100 offered = 185%
    });

    test('loadSubscriptions filters by ipoId', () async {
      await provider.loadSubscriptions(ipoId: 'ipo-awash-bank-002');

      expect(provider.subscriptions.length, 1);
      expect(provider.subscriptions.first.symbol, 'AWASH');
    });

    test('loadSubscriptionById retrieves matching subscription', () async {
      await provider.loadSubscriptionById('sub-mock-001');

      expect(provider.selectedSubscription, isNotNull);
      expect(provider.selectedSubscription!.investorName, 'Abebe Bikila');
      expect(provider.errorMessage, isNull);
    });
  });

  group('ApiSubscriptionsRepository', () {
    test('getSubscriptions queries /subscriptions with proper params and deserializes', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/subscriptions');
        expect(request.url.queryParameters['ipo_id'], 'ipo-ethio-telecom-001');

        return http.Response(
          json.encode({
            'data': [
              {
                'id': 'sub-api-001',
                'ipo_id': 'ipo-ethio-telecom-001',
                'ipo_title': 'Ethio Telecom Class A Shares',
                'ipo_symbol': 'ETHTEL',
                'company_name': 'Ethio Telecom SC',
                'investor_id': 'usr-inv-001',
                'investor_name': 'Test Investor',
                'investor_email': 'test@example.com',
                'quantity': 30,
                'price_per_share_minor': 30000,
                'total_amount_minor': 900000,
                'allocated_quantity': 30,
                'status': 'settled',
                'idempotency_key': 'idem-api-001',
                'created_at': '2026-03-24T12:00:00Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = ApiSubscriptionsRepository(apiClient: apiClient);

      final result = await repo.getSubscriptions(ipoId: 'ipo-ethio-telecom-001');
      expect(result.length, 1);
      expect(result.first.id, 'sub-api-001');
      expect(result.first.isFull, isTrue);
    });
  });

  group('SubscriptionsListScreen Widget', () {
    testWidgets('renders KPI cards, search bar, and subscription rows', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = MockSubscriptionsRepository();
      final provider = SubscriptionsProvider(repository: repository);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubscriptionsRepository>.value(value: repository),
            ChangeNotifierProvider<SubscriptionsProvider>.value(value: provider),
          ],
          child: const MaterialApp(
            home: SubscriptionsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Subscription Management'), findsOneWidget);
      expect(find.text('Total Subscriptions'), findsOneWidget);
      expect(find.text('Requested Shares'), findsOneWidget);
      expect(find.text('Committed Volume'), findsOneWidget);

      // Verify Table Contents
      expect(find.text('Ethio Telecom Class A Shares'), findsWidgets);
      expect(find.text('Abebe Bikila'), findsOneWidget);
      expect(find.text('Almaz Ayana'), findsOneWidget);
      expect(find.text('Kenenisa Bekele'), findsOneWidget);
    });
  });
}
