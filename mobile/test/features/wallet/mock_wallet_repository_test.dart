import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/wallet/repositories/mock_wallet_repository.dart';

void main() {
  late MockWalletRepository repo;

  setUp(() => repo = MockWalletRepository());

  group('MockWalletRepository.getWalletSummary', () {
    test('returns summary with ETB currency', () async {
      final summary = await repo.getWalletSummary();
      expect(summary.currency, 'ETB');
    });

    test('total balance is available + reserved', () async {
      final s = await repo.getWalletSummary();
      final total = s.availableBalanceDisplay + s.reservedBalanceDisplay;
      expect(total, closeTo(s.totalBalanceDisplay, 0.01));
    });

    test('available balance is non-negative', () async {
      final s = await repo.getWalletSummary();
      expect(s.availableBalanceDisplay, greaterThanOrEqualTo(0));
    });
  });

  group('MockWalletRepository.getTransactions', () {
    test('returns non-empty transaction list', () async {
      final result = await repo.getTransactions();
      expect(result.items, isNotEmpty);
    });

    test('transactions contain a RESERVATION entry', () async {
      final result = await repo.getTransactions();
      final hasReservation = result.items.any((t) => t.type == 'RESERVATION');
      expect(hasReservation, isTrue);
    });

    test('transactions contain a CREDIT entry', () async {
      final result = await repo.getTransactions();
      final hasCredit = result.items.any((t) => t.type == 'CREDIT');
      expect(hasCredit, isTrue);
    });

    test('all transactions have non-empty ids', () async {
      final result = await repo.getTransactions();
      for (final tx in result.items) {
        expect(tx.id, isNotEmpty);
      }
    });

    test('all amounts parse to positive doubles', () async {
      final result = await repo.getTransactions();
      for (final tx in result.items) {
        expect(tx.amountDisplay, greaterThan(0));
      }
    });
  });
}
