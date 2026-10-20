import '../models/wallet_models.dart';

/// Contract for wallet and transaction data operations.
abstract interface class WalletRepository {
  /// Returns the current user's wallet summary.
  Future<WalletSummary> getWalletSummary();

  /// Returns paginated transaction history for the current user.
  Future<PaginatedTransactions> getTransactions({
    int page = 1,
    int pageSize = 20,
  });
}
