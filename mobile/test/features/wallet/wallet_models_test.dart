import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/wallet/models/wallet_models.dart';

void main() {
  group('WalletSummary.fromJson', () {
    final validJson = {
      'id': 'wallet-1',
      'currency': 'ETB',
      'availableBalance': '7000.00',
      'reservedBalance': '3000.00',
      'totalBalance': '10000.00',
    };

    test('parses all fields', () {
      final summary = WalletSummary.fromJson(validJson);
      expect(summary.id, 'wallet-1');
      expect(summary.currency, 'ETB');
      expect(summary.availableBalance, '7000.00');
      expect(summary.reservedBalance, '3000.00');
      expect(summary.totalBalance, '10000.00');
    });

    test('display helpers parse to double', () {
      final summary = WalletSummary.fromJson(validJson);
      expect(summary.availableBalanceDisplay, 7000.0);
      expect(summary.reservedBalanceDisplay, 3000.0);
      expect(summary.totalBalanceDisplay, 10000.0);
    });

    test('handles integer amounts from backend', () {
      final json = {
        'id': 'w2',
        'availableBalance': 5000,
        'reservedBalance': 1000,
        'totalBalance': 6000,
      };
      final summary = WalletSummary.fromJson(json);
      expect(summary.availableBalanceDisplay, 5000.0);
    });

    test('defaults currency to ETB', () {
      final json = {
        'id': 'w3',
        'availableBalance': '0',
        'reservedBalance': '0',
        'totalBalance': '0',
      };
      final summary = WalletSummary.fromJson(json);
      expect(summary.currency, 'ETB');
    });
  });

  group('WalletTransaction.fromJson', () {
    final validJson = {
      'id': 'tx-1',
      'type': 'RESERVATION',
      'status': 'COMPLETED',
      'amount': '3000.00',
      'currency': 'ETB',
      'createdAt': '2026-10-15T10:30:00.000Z',
      'description': 'IPO subscription',
      'referenceId': 'sub-001',
      'referenceType': 'SUBSCRIPTION',
    };

    test('parses all fields', () {
      final tx = WalletTransaction.fromJson(validJson);
      expect(tx.id, 'tx-1');
      expect(tx.type, 'RESERVATION');
      expect(tx.status, 'COMPLETED');
      expect(tx.amount, '3000.00');
      expect(tx.description, 'IPO subscription');
      expect(tx.referenceType, 'SUBSCRIPTION');
    });

    test('isDebit is true for RESERVATION type', () {
      final tx = WalletTransaction.fromJson(validJson);
      expect(tx.isDebit, isTrue);
      expect(tx.isCredit, isFalse);
    });

    test('isCredit is true for CREDIT type', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'CREDIT'});
      expect(tx.isCredit, isTrue);
      expect(tx.isDebit, isFalse);
    });

    test('isCredit is true for REFUND type', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'REFUND'});
      expect(tx.isCredit, isTrue);
    });

    test('isCredit is true for RELEASE type', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'RELEASE'});
      expect(tx.isCredit, isTrue);
    });

    test('isDebit is true for DEBIT type', () {
      final tx = WalletTransaction.fromJson({...validJson, 'type': 'DEBIT'});
      expect(tx.isDebit, isTrue);
    });

    test('amountDisplay parses correctly', () {
      final tx = WalletTransaction.fromJson(validJson);
      expect(tx.amountDisplay, 3000.0);
    });

    test('createdAt is parsed as DateTime', () {
      final tx = WalletTransaction.fromJson(validJson);
      expect(tx.createdAt.year, 2026);
      expect(tx.createdAt.month, 10);
    });

    test('handles null optional fields', () {
      final minimal = {
        'id': 'tx-2',
        'type': 'CREDIT',
        'status': 'COMPLETED',
        'amount': '500.00',
        'createdAt': '2026-10-01T00:00:00.000Z',
      };
      final tx = WalletTransaction.fromJson(minimal);
      expect(tx.description, isNull);
      expect(tx.referenceId, isNull);
      expect(tx.currency, 'ETB');
    });
  });

  group('PaginatedTransactions.fromJson', () {
    test('parses items list', () {
      final json = {
        'items': [
          {
            'id': 'tx-1',
            'type': 'CREDIT',
            'status': 'COMPLETED',
            'amount': '1000.00',
            'createdAt': '2026-10-01T00:00:00.000Z',
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 20,
      };
      final paginated = PaginatedTransactions.fromJson(json);
      expect(paginated.items.length, 1);
      expect(paginated.total, 1);
      expect(paginated.hasMore, isFalse);
    });

    test('handles empty list', () {
      final json = {'items': [], 'total': 0, 'page': 1, 'pageSize': 20};
      final result = PaginatedTransactions.fromJson(json);
      expect(result.items, isEmpty);
    });
  });
}
