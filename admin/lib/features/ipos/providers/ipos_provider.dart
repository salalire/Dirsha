import 'package:flutter/foundation.dart';
import '../models/ipo_application.dart';
import '../repositories/ipo_repository.dart';

class IposProvider extends ChangeNotifier {
  IposProvider({required IpoRepository repository})
      : _repository = repository;

  final IpoRepository _repository;

  List<IpoApplication> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;
  IpoApplication? _selectedApplication;
  bool _isSubmitting = false;
  String? _submitError;
  String? _submitSuccess;

  List<IpoApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  IpoApplication? get selectedApplication => _selectedApplication;
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
    _isLoading = true;
    _errorMessage = null;
    _selectedApplication = null;
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
      _submitSuccess = 'IPO application approved successfully.';
      await loadApplications();
      if (_selectedApplication?.id == id) {
        await loadApplicationById(id);
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

  Future<bool> reject(String id, {required String reason}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
    try {
      await _repository.rejectApplication(id, reason: reason);
      _submitSuccess = 'IPO application rejected.';
      await loadApplications();
      if (_selectedApplication?.id == id) {
        await loadApplicationById(id);
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
