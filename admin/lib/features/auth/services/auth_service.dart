import '../models/admin_user.dart';

/// Abstract authentication service interface.
///
/// The UI depends on this interface, not on any specific implementation.
/// This allows swapping between mock (Phase 1 dev) and real API auth
/// without changing any screen code.
abstract class AuthService {
  /// Signs in with email and password.
  /// Returns an [AdminUser] on success.
  /// Throws [Exception] with a user-facing message on failure.
  Future<AdminUser> signIn({
    required String email,
    required String password,
  });

  /// Signs out the current session.
  Future<void> signOut();

  /// Returns the currently authenticated user, or null if not signed in.
  /// This is used to restore session state on app start.
  Future<AdminUser?> getCurrentUser();
}
