import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/core/errors/app_exception.dart';
import 'package:dirsha_mobile/features/subscriptions/models/subscription_models.dart';
import 'package:dirsha_mobile/features/subscriptions/providers/subscription_provider.dart';
import 'package:dirsha_mobile/features/subscriptions/repositories/mock_subscription_repository.dart';

void main() {
  group('SubscriptionProvider', () {
    late MockSubscriptionRepository repository;
    late SubscriptionProvider provider;

    setUp(() {
      repository = MockSubscriptionRepository();
      provider = SubscriptionProvider(repository: repository);
    });

    test('initial state is idle with no errors', () {
      expect(provider.isSubmitting, isFalse);
      expect(provider.error, isNull);
      expect(provider.lastCreated, isNull);
    });

    test('submitSubscription successfully creates a reservation', () async {
      final sub = await provider.submitSubscription(
        ipoId: 'ipo-test-1',
        quantity: 25,
        idempotencyKey: 'idem-test-key-1',
      );

      expect(sub, isNotNull);
      expect(sub!.quantity, 25);
      expect(sub.status, SubscriptionStatus.reserved);
      expect(provider.isSubmitting, isFalse);
      expect(provider.lastCreated, equals(sub));
      expect(provider.error, isNull);
    });

    test('handles idempotency replay smoothly', () async {
      final sub1 = await provider.submitSubscription(
        ipoId: 'ipo-test-1',
        quantity: 25,
        idempotencyKey: 'idem-test-replay',
      );
      expect(sub1, isNotNull);

      // Replay with identical key and quantity
      final sub2 = await provider.submitSubscription(
        ipoId: 'ipo-test-1',
        quantity: 25,
        idempotencyKey: 'idem-test-replay',
      );
      expect(sub2, isNotNull);
      expect(sub2!.id, equals(sub1!.id));
    });

    test('captures conflict error when active subscription exists', () async {
      await provider.submitSubscription(
        ipoId: 'ipo-test-conflict',
        quantity: 10,
        idempotencyKey: 'idem-conflict-1',
      );

      final second = await provider.submitSubscription(
        ipoId: 'ipo-test-conflict',
        quantity: 20,
        idempotencyKey: 'idem-conflict-2',
      );

      expect(second, isNull);
      expect(provider.error, isA<ApiException>());
      expect(provider.isConflict, isTrue);
      expect(provider.errorCode, 'CONFLICT');
    });

    test('loadSubscriptions retrieves list and populates subscriptions', () async {
      await provider.loadSubscriptions();

      expect(provider.isLoading, isFalse);
      expect(provider.subscriptions.isNotEmpty, isTrue);
      expect(provider.error, isNull);
    });

    test('getSubscriptionDetails fetches existing subscription by id', () async {
      await provider.loadSubscriptions();
      final firstId = provider.subscriptions.first.id;

      final details = await provider.getSubscriptionDetails(firstId);
      expect(details, isNotNull);
      expect(details!.id, firstId);
    });
  });
}
