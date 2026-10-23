import 'package:flutter/foundation.dart';
import '../models/audit_event.dart';
import '../repositories/audit_repository.dart';

class AuditProvider extends ChangeNotifier {
  AuditProvider({required AuditRepository repository})
      : _repository = repository;

  final AuditRepository _repository;

  List<AuditEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _actionFilter;
  String _searchQuery = '';

  List<AuditEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionFilter => _actionFilter;
  String get searchQuery => _searchQuery;

  List<AuditEvent> get filteredEvents {
    return _events.where((e) {
      final matchesAction = _actionFilter == null ||
          _actionFilter!.isEmpty ||
          e.action == _actionFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          e.action.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.targetResource.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.referenceId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (e.actorId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesAction && matchesSearch;
    }).toList();
  }

  Future<void> loadEvents({String? action}) async {
    _isLoading = true;
    _errorMessage = null;
    _actionFilter = action;
    notifyListeners();
    try {
      _events = await _repository.getRecentEvents(limit: 100, action: action);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim();
    notifyListeners();
  }

  void setActionFilter(String? action) {
    _actionFilter = action;
    loadEvents(action: action);
  }
}
