import '../models/wallet_models.dart';
import 'wallet_repository.dart';

/// Development mock for [WalletRepository].
///
/// IMPORTANT: These balances and transactions are completely fabricated
/// for UI development only. They are NOT a real user's account balance.
/// The [MockDataBanner] must remain visible on all wallet screens using
/// this repository.
///
/// Simulated test funds only — no real money is involved.
class MockWalletRepository implements WalletRepository {
  static const _delay = Duration(milliseconds: 600);

  static const _summary = WalletSummary(
    id: 'mock-wallet-001',
    currency: 'ETB',
    availableBalance: '7000.00',
    reservedBalance: '3000.00',
    totalBalance: '10000.00',
  );

  // Transactions listed newest-first, as expected from the backend.
  static final _transactions = <WalletTransaction>[
    WalletTransaction(
      id: 'mock-tx-001',
      type: 'RESERVATION',
      status: 'COMPLETED',
      amount: '3000.00',
      currency: 'ETB',
      createdAt: DateTime(2026, 10, 15, 10, 30),
      description: 'IPO subscription reservation — Dev Corp A [MOCK]',
      referenceId: 'mock-ipo-001',
      referenceType: 'SUBSCRIPTION',
    ),
    WalletTransaction(
      id: 'mock-tx-002',
      type: 'CREDIT',
      status: 'COMPLETED',
      amount: '10000.00',
      currency: 'ETB',
      createdAt: DateTime(2026, 10, 10, 9, 0),
      description: 'Initial test funds credited — development environment only',
      referenceType: 'TEST_CREDIT',
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
}
