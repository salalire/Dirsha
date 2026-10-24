import 'dart:math';

import 'package:dio/dio.dart';

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
      queryParameters: {'page': page, 'page_size': pageSize},
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

  @override
  Future<void> addTestFunds(int amountMinor) async {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final idempotencyKey =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';

    await _client.post<Map<String, dynamic>?>(
      '/dev/test-funds',
      data: {'amount_minor': amountMinor},
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }
}
