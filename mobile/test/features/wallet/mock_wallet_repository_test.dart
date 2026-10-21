import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/wallet/repositories/mock_wallet_repository.dart';

void main() {
  late MockWalletRepository repo;

  setUp(() => repo = MockWalletRepository());

  group('MockWalletRepository.getWalletSummary', () {
    test('returns ETB currency', () async {
      final s = await repo.getWalletSummary();
      expect(s.currency, 'ETB');
    });

    test('available + reserved equals total (santim)', () async {
      final s = await repo.getWalletSummary();
      expect(s.available.santim + s.reserved.santim, s.total.santim);
    });

    test('available balance is ETB 7000 (700000 santim)', () async {
      final s = await repo.getWalletSummary();
      expect(s.available.santim, 700000);
      expect(s.available.etb, 7000.0);
    });

    test('reserved balance is ETB 3000 (300000 santim)', () async {
      final s = await repo.getWalletSummary();
      expect(s.reserved.santim, 300000);
    });

    test('available balance is non-negative', () async {
      final s = await repo.getWalletSummary();
      expect(s.available.santim, greaterThanOrEqualTo(0));
    });
  });

  group('MockWalletRepository.getTransactions', () {
    test('returns non-empty transaction list', () async {
      final result = await repo.getTransactions();
      expect(result.items, isNotEmpty);
    });

    test('contains a RESERVATION transaction', () async {
      final result = await repo.getTransactions();
      expect(result.items.any((t) => t.type == 'RESERVATION'), isTrue);
    });

    test('contains a CREDIT transaction', () async {
      final result = await repo.getTransactions();
      expect(result.items.any((t) => t.type == 'CREDIT'), isTrue);
    });

    test('all transactions have non-empty ids', () async {
      final result = await repo.getTransactions();
      for (final tx in result.items) {
        expect(tx.id, isNotEmpty);
      }
    });

    test('all amounts are positive santim', () async {
      final result = await repo.getTransactions();
      for (final tx in result.items) {
        expect(tx.amount.santim, greaterThan(0));
      }
    });

    test('RESERVATION amount is ETB 3000 (300000 santim)', () async {
      final result = await repo.getTransactions();
      final reservation = result.items.firstWhere(
        (t) => t.type == 'RESERVATION',
      );
      expect(reservation.amount.santim, 300000);
      expect(reservation.amount.etb, 3000.0);
    });
  });
}
