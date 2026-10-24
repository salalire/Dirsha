// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../models/wallet_models.dart';
import '../repositories/wallet_repository.dart';

/// Manages wallet summary and transaction history state.
class WalletProvider extends ChangeNotifier {
  WalletProvider({required WalletRepository repository})
    : _repository = repository;

  final WalletRepository _repository;

  WalletSummary? _summary;
  List<WalletTransaction> _transactions = [];
  bool _isSummaryLoading = false;
  bool _isTransactionsLoading = false;
  Object? _summaryError;
  Object? _transactionsError;
  bool _hasLoaded = false;

  WalletSummary? get summary => _summary;
  List<WalletTransaction> get transactions => _transactions;
  bool get isSummaryLoading => _isSummaryLoading;
  bool get isTransactionsLoading => _isTransactionsLoading;
  Object? get summaryError => _summaryError;
  Object? get transactionsError => _transactionsError;
  bool get hasLoaded => _hasLoaded;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && _hasLoaded) return;
    await Future.wait([_loadSummary(), _loadTransactions()]);
    _hasLoaded = true;
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> _loadSummary() async {
    _isSummaryLoading = true;
    _summaryError = null;
    notifyListeners();
    try {
      _summary = await _repository.getWalletSummary();
    } on AppException catch (e) {
      _summaryError = e;
    } catch (e) {
      _summaryError = e;
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTransactions() async {
    _isTransactionsLoading = true;
    _transactionsError = null;
    notifyListeners();
    try {
      final result = await _repository.getTransactions();
      _transactions = result.items;
    } on AppException catch (e) {
      _transactionsError = e;
    } catch (e) {
      _transactionsError = e;
    } finally {
      _isTransactionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTestFunds([int amountMinor = 1000000]) async {
    _isSummaryLoading = true;
    _summaryError = null;
    notifyListeners();
    try {
      await _repository.addTestFunds(amountMinor);
      await refresh();
    } on AppException catch (e) {
      _summaryError = e;
      rethrow;
    } catch (e) {
      _summaryError = e;
      rethrow;
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }
}
