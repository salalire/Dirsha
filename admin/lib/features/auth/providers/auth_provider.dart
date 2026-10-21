import 'package:flutter/foundation.dart';
import '../models/admin_user.dart';
import '../services/auth_service.dart';

/// Authentication state for the entire admin app.
///
/// Screens listen to this provider to know if the user is signed in,
/// loading, or if an error occurred.
///
/// IMPORTANT: This is a UI state helper only. The actual security
/// boundary is the backend — every admin API call requires a valid
/// server-side session. Client-side auth state is for navigation only.
class AdminAuthProvider extends ChangeNotifier {
  AdminAuthProvider({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;

  AdminUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  AdminUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Initialisation ─────────────────────────────────────────────────────────
  /// Called once at app startup to restore any existing session.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.getCurrentUser();
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Sign in ────────────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } finally {
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any displayed error (e.g. when the user starts typing again).
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
