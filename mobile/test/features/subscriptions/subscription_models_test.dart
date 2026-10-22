import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/subscriptions/models/subscription_models.dart';

void main() {
  group('SubscriptionModel and SubscriptionStatus contracts', () {
    test('SubscriptionStatus parses all backend enum strings correctly', () {
      expect(SubscriptionStatus.fromString('reserved'),
          SubscriptionStatus.reserved);
      expect(SubscriptionStatus.fromString('allocated'),
          SubscriptionStatus.allocated);
      expect(SubscriptionStatus.fromString('partially_allocated'),
          SubscriptionStatus.partiallyAllocated);
      expect(SubscriptionStatus.fromString('released'),
          SubscriptionStatus.released);
      expect(SubscriptionStatus.fromString('cancelled'),
          SubscriptionStatus.cancelled);
      expect(SubscriptionStatus.fromString('invalid'),
          SubscriptionStatus.unknown);
      expect(
          SubscriptionStatus.fromString(null), SubscriptionStatus.unknown);
    });

    test('SubscriptionModel decodes backend snake_case JSON envelope accurately', () {
      final json = {
        'id': 'sub-uuid-1234',
        'ipo_id': 'ipo-uuid-5678',
        'investor_id': 'inv-uuid-9999',
        'quantity': 30,
        'amount_minor': 300000,
        'allocated_quantity': 0,
        'status': 'reserved',
        'reservation_ledger_entry_id': 'led-uuid-0000',
        'created_at': '2026-10-22T08:00:00.000Z',
        'updated_at': '2026-10-22T08:00:00.000Z',
      };

      final model = SubscriptionModel.fromJson(json);

      expect(model.id, 'sub-uuid-1234');
      expect(model.ipoId, 'ipo-uuid-5678');
      expect(model.investorId, 'inv-uuid-9999');
      expect(model.quantity, 30);
      expect(model.amountMinor, 300000);
      expect(model.amountEtb, 3000.00);
      expect(model.allocatedQuantity, 0);
      expect(model.status, SubscriptionStatus.reserved);
      expect(model.reservationLedgerEntryId, 'led-uuid-0000');
      expect(model.createdAt, DateTime.parse('2026-10-22T08:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-10-22T08:00:00.000Z'));
    });
  });
}
