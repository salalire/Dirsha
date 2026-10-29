import 'package:dirsha_mobile/core/money/money.dart';
import '../models/wallet_models.dart';
import 'wallet_repository.dart';

/// Development mock for [WalletRepository].
///
/// IMPORTANT: These balances and transactions are completely fabricated
/// for UI development only. They are NOT a real user's account balance.
/// The [MockDataBanner] must remain visible on all wallet screens using
/// this repository.
///
/// Amounts use integer santim (1 ETB = 100 santim) to match the
/// confirmed backend contract. ETB values displayed in the UI:
///   Available:    ETB 7,000.00  →  700_000 santim
///   Reserved:     ETB 3,000.00  →  300_000 santim
///   Total:        ETB 10,000.00 →  1_000_000 santim
///   Reservation:  ETB 3,000.00  →  300_000 santim
///   Credit:       ETB 10,000.00 →  1_000_000 santim
class MockWalletRepository implements WalletRepository {
  static const _delay = Duration(milliseconds: 600);

  static final _summary = WalletSummary(
    id: 'mock-wallet-001',
    currency: 'ETB',
    available: Money(700000), // ETB 7,000.00
    reserved: Money(300000), // ETB 3,000.00
    total: Money(1000000), // ETB 10,000.00
  );

  static final _transactions = <WalletTransaction>[
    WalletTransaction(
      id: 'mock-tx-001',
      type: 'RESERVATION',
      status: 'COMPLETED',
      amount: Money(300000), // ETB 3,000.00
      currency: 'ETB',
      createdAt: DateTime(2026, 10, 15, 10, 30),
      description: 'IPO subscription reservation — Ethio Telecom Enterprise',
      referenceId: 'mock-ipo-001',
      referenceType: 'SUBSCRIPTION',
    ),
    WalletTransaction(
      id: 'mock-tx-002',
      type: 'CREDIT',
      status: 'COMPLETED',
      amount: Money(1000000), // ETB 10,000.00
      currency: 'ETB',
      createdAt: DateTime(2026, 10, 10, 9, 0),
      description: 'Account activation deposit — Telebirr',
      referenceType: 'BANK_TRANSFER',
    ),
  ];

  @override
  Future<WalletSummary> getWalletSummary() async {
    await Future.delayed(_delay);
    return _summary;
  }

  @override
  Future<PaginatedTransactions> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(_delay);
    return PaginatedTransactions(
      items: _transactions,
      total: _transactions.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> addTestFunds(int amountMinor) async {
    await Future.delayed(_delay);
  }
}
