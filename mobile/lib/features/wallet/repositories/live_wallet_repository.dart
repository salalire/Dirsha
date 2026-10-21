import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/wallet_models.dart';
import 'wallet_repository.dart';

/// Live implementation of [WalletRepository].
///
/// STATUS: Inactive. Replaces [MockWalletRepository] once:
///   1. Member 2 confirms GET /wallets/me and
///      GET /wallets/me/transactions endpoints.
///   2. [AppConfig.useMockRepositories] is set to false.
///
/// DEPENDENCY ON MEMBER 2:
///   - Confirm endpoint paths (/wallets/me vs /wallets/:userId).
///   - Confirm monetary field representation.
///   - Confirm transaction type and status enum values.
///   - Confirm pagination envelope shape.
class LiveWalletRepository implements WalletRepository {
  const LiveWalletRepository({required ApiClient apiClient})
    : _client = apiClient;

  final ApiClient _client;

  @override
  Future<WalletSummary> getWalletSummary() async {
    final data = await _client.get<Map<String, dynamic>?>('/wallets/me');
    if (data == null) {
      throw const ParseException(message: 'Wallet summary response was empty.');
    }
    try {
      return WalletSummary.fromJson(data);
    } catch (e) {
      throw ParseException(
        message: 'Could not parse wallet summary.',
        cause: e,
      );
    }
  }

  @override
  Future<PaginatedTransactions> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get<Map<String, dynamic>?>(
      '/wallets/me/transactions',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    if (data == null) {
      throw const ParseException(
        message: 'Transaction history response was empty.',
      );
    }
    try {
      return PaginatedTransactions.fromJson(data);
    } catch (e) {
      throw ParseException(
        message: 'Could not parse transaction history.',
        cause: e,
      );
    }
  }
}
