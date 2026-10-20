// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

/// Authentication state for the entire app.
///
/// Consumed by [AuthGuard] in the router to decide whether to show the
/// sign-in screen or the main app.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Manages authentication state and exposes it to the widget tree via
/// [ChangeNotifier] / [Provider].
///
/// Screens interact with auth through this provider only — they do not
/// call the repository directly.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------------
  // Startup — check whether a stored token is still valid
  // ---------------------------------------------------------------------------

  /// Called once at app startup. Attempts to fetch the current user to
  /// determine whether a stored token is still valid.
  ///
  /// Sets status to [AuthStatus.authenticated] or [AuthStatus.unauthenticated].
  /// Never throws — the router reads [status] after this completes.
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      final user = await _repository.getCurrentUser();
      _user = user;
      _status = AuthStatus.authenticated;
    } on UnauthorizedException {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } on AppException {
      // Network error or server error — treat as unauthenticated for startup.
      _status = AuthStatus.unauthenticated;
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  Future<bool> login(LoginRequest request) async {
    _clearError();
    _setLoading(true);
    try {
      final result = await _repository.login(request);
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  Future<bool> register(RegisterRequest request) async {
    _clearError();
    _setLoading(true);
    try {
      final result = await _repository.register(request);
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    _clearError();
    _setLoading(true);
    try {
      await _repository.logout();
    } on AppException {
      // Silently clear local state even if server logout fails.
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
    }
  }

  /// Called by [AuthInterceptor] when a token refresh fails.
  /// Forces a sign-out from outside the normal user flow.
  void forceSignOut() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void clearError() => _clearError();

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
