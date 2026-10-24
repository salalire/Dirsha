// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../models/portfolio_models.dart';
import '../repositories/portfolio_repository.dart';

class PortfolioProvider extends ChangeNotifier {
  PortfolioProvider({required PortfolioRepository repository})
      : _repository = repository;

  final PortfolioRepository _repository;

  PortfolioModel? _portfolio;
  bool _isLoading = false;
  Object? _error;

  PortfolioModel? get portfolio => _portfolio;
  List<HoldingModel> get holdings => _portfolio?.holdings ?? const [];
  PortfolioSummaryModel? get summary => _portfolio?.summary;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  String? get errorMessage {
    if (_error == null) return null;
    if (_error is AppException) return (_error as AppException).message;
    return _error.toString();
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _portfolio = await _repository.getPortfolio();
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _error = null;
    try {
      _portfolio = await _repository.getPortfolio();
    } catch (e) {
      _error = e;
    } finally {
      notifyListeners();
    }
  }
}
