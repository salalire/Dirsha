// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../models/ipo_models.dart';
import '../repositories/ipo_repository.dart';

/// Manages the IPO list state.
class IpoListProvider extends ChangeNotifier {
  IpoListProvider({required IpoRepository repository})
    : _repository = repository;

  final IpoRepository _repository;

  List<IpoSummary> _ipos = [];
  bool _isLoading = false;
  Object? _error;
  bool _hasLoaded = false;

  List<IpoSummary> get ipos => _ipos;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  bool get hasLoaded => _hasLoaded;
  bool get isEmpty => _hasLoaded && !_isLoading && _ipos.isEmpty;

  Future<void> load({bool refresh = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !refresh) return;

    _isLoading = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final result = await _repository.getIpos();
      _ipos = result.items;
      _error = null;
      _hasLoaded = true;
    } on AppException catch (e) {
      _error = e;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(refresh: true);
}

/// Manages the detail state for a single IPO.
class IpoDetailProvider extends ChangeNotifier {
  IpoDetailProvider({required IpoRepository repository})
    : _repository = repository;

  final IpoRepository _repository;

  IpoDetail? _detail;
  bool _isLoading = false;
  Object? _error;
  String? _currentId;

  IpoDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> load(String id) async {
    if (_isLoading) return;
    // Avoid re-fetching if we already have the correct detail.
    if (_currentId == id && _detail != null && _error == null) return;

    _isLoading = true;
    _error = null;
    _currentId = id;
    notifyListeners();

    try {
      _detail = await _repository.getIpoById(id);
    } on AppException catch (e) {
      _error = e;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String id) async {
    _detail = null;
    _currentId = null;
    await load(id);
  }
}
