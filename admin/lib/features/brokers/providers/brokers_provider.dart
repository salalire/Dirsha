import 'package:flutter/foundation.dart';
import '../models/broker_application.dart';
import '../repositories/broker_repository.dart';

class BrokersProvider extends ChangeNotifier {
  BrokersProvider({required BrokerRepository repository})
      : _repository = repository;

  final BrokerRepository _repository;

  List<BrokerApplication> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;
  BrokerApplication? _selectedApplication;
  bool _isSubmitting = false;
  String? _submitError;
  String? _submitSuccess;

  List<BrokerApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BrokerApplication? get selectedApplication => _selectedApplication;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  String? get submitSuccess => _submitSuccess;

  Future<void> loadApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _applications = await _repository.getApplications();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadApplicationById(String id) async {
    _isLoading = _selectedApplication == null;
    _errorMessage = null;
    notifyListeners();
    try {
      _selectedApplication = await _repository.getApplicationById(id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approve(String id, {String? notes}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
    try {
      await _repository.approveApplication(id, notes: notes);
      _submitSuccess = 'Broker application approved successfully.';
      await loadApplications();
      await loadApplicationById(id);
      return true;
    } catch (e) {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> reject(String id, {required String reason}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
    try {
      await _repository.rejectApplication(id, reason: reason);
      _submitSuccess = 'Broker application rejected.';
      await loadApplications();
      await loadApplicationById(id);
      return true;
    } catch (e) {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> requestAdditionalInfo(String id, {required String message}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
    try {
      await _repository.requestAdditionalInfo(id, message: message);
      _submitSuccess = 'Additional information requested from broker.';
      await loadApplications();
      await loadApplicationById(id);
      return true;
    } catch (e) {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> reviewDocument(
      String documentId, {required String status, String? notes}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
    try {
      await _repository.reviewDocument(documentId,
          status: status, notes: notes);
      _submitSuccess = 'Document review recorded as $status.';
      if (_selectedApplication != null) {
        await loadApplicationById(_selectedApplication!.id);
      }
      return true;
    } catch (e) {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearFeedback() {
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
  }
}
