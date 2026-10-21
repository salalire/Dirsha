import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/wallet/models/wallet_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // WalletSummary — live API format (integer santim)
  // ---------------------------------------------------------------------------
  group('WalletSummary.fromJson — santim integer fields (live API format)', () {
    final validJson = {
      'id': 'wallet-1',
      'currency': 'ETB',
      'available_minor': 700000,
      'reserved_minor': 300000,
      'total_minor': 1000000,
    };

    test('parses id and currency', () {
      final s = WalletSummary.fromJson(validJson);
      expect(s.id, 'wallet-1');
      expect(s.currency, 'ETB');
    });

    test('parses santim amounts as Money', () {
      final s = WalletSummary.fromJson(validJson);
      expect(s.available.santim, 700000);
      expect(s.reserved.santim, 300000);
      expect(s.total.santim, 1000000);
    });

    test('ETB display values are santim / 100', () {
      final s = WalletSummary.fromJson(validJson);
      expect(s.available.etb, 7000.0);
      expect(s.reserved.etb, 3000.0);
      expect(s.total.etb, 10000.0);
    });

    test('700000 santim is ETB 7000, not ETB 700000', () {
      final s = WalletSummary.fromJson(validJson);
      expect(s.available.etb, isNot(700000.0));
      expect(s.available.etb, 7000.0);
    });
  });

  // ---------------------------------------------------------------------------
  // WalletSummary — legacy mock format (decimal ETB string)
  // ---------------------------------------------------------------------------
  group(
    'WalletSummary.fromJson — legacy camelCase string fields (mock format)',
    () {
      final legacyJson = {
        'id': 'wallet-2',
        'currency': 'ETB',
        'availableBalance': '7000.00',
        'reservedBalance': '3000.00',
        'totalBalance': '10000.00',
      };

      test('parses legacy ETB decimal strings via fallback key', () {
        final s = WalletSummary.fromJson(legacyJson);
        // "7000.00" treated as ETB → 700000 santim
        expect(s.available.santim, 700000);
        expect(s.reserved.santim, 300000);
        expect(s.total.santim, 1000000);
      });

      test('ETB display is correct from legacy format', () {
        final s = WalletSummary.fromJson(legacyJson);
        expect(s.available.etb, 7000.0);
      });
    },
  );

  group('WalletSummary.fromJson — defaults', () {
    test('defaults currency to ETB', () {
      final json = {
        'id': 'w3',
        'available_minor': 0,
        'reserved_minor': 0,
        'total_minor': 0,
      };
      expect(WalletSummary.fromJson(json).currency, 'ETB');
    });
  });

  // ---------------------------------------------------------------------------
  // WalletTransaction
  // ---------------------------------------------------------------------------
  group('WalletTransaction.fromJson — santim fields', () {
    final validJson = {
      'id': 'tx-1',
      'type': 'RESERVATION',
      'status': 'COMPLETED',
      'amount_minor': 300000,
      'currency': 'ETB',
      'createdAt': '2026-10-15T10:30:00.000Z',
      'description': 'IPO subscription',
      'referenceId': 'sub-001',
      'referenceType': 'SUBSCRIPTION',
    };

    test('parses amount_minor as Money', () {
      final tx = WalletTransaction.fromJson(validJson);
      expect(tx.amount.santim, 300000);
      expect(tx.amount.etb, 3000.0);
    });

    test('isDebit true for RESERVATION', () {
      expect(WalletTransaction.fromJson(validJson).isDebit, isTrue);
    });

    test('isCredit true for CREDIT', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'CREDIT'});
      expect(tx.isCredit, isTrue);
    });

    test('isCredit true for REFUND', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'REFUND'});
      expect(tx.isCredit, isTrue);
    });

    test('isCredit true for RELEASE', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'RELEASE'});
      expect(tx.isCredit, isTrue);
    });

    test('isDebit true for DEBIT', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'DEBIT'});
      expect(tx.isDebit, isTrue);
    });

    test('createdAt parses correctly', () {
      final tx = WalletTransaction.fromJson(validJson);
      expect(tx.createdAt.year, 2026);
      expect(tx.createdAt.month, 10);
    });

    test('handles null optional fields', () {
      final minimal = {
        'id': 'tx-2',
        'type': 'CREDIT',
        'status': 'COMPLETED',
        'amount_minor': 100000,
        'createdAt': '2026-10-01T00:00:00.000Z',
      };
      final tx = WalletTransaction.fromJson(minimal);
      expect(tx.description, isNull);
      expect(tx.referenceId, isNull);
      expect(tx.currency, 'ETB');
    });

    test('toJson serializes amount as santim integer', () {
      final tx = WalletTransaction.fromJson(validJson);
      final json = tx.toJson();
      expect(json['amount_minor'], 300000);
    });
  });

  // ---------------------------------------------------------------------------
  // PaginatedTransactions
  // ---------------------------------------------------------------------------
  group('PaginatedTransactions.fromJson', () {
    test('parses items list', () {
      final json = {
        'items': [
          {
            'id': 'tx-1',
            'type': 'CREDIT',
            'status': 'COMPLETED',
            'amount_minor': 100000,
            'createdAt': '2026-10-01T00:00:00.000Z',
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 20,
      };
      final result = PaginatedTransactions.fromJson(json);
      expect(result.items.length, 1);
      expect(result.total, 1);
      expect(result.hasMore, isFalse);
    });

    test('handles empty list', () {
      final json = {'items': [], 'total': 0, 'page': 1, 'pageSize': 20};
      final result = PaginatedTransactions.fromJson(json);
      expect(result.items, isEmpty);
    });
  });
}
