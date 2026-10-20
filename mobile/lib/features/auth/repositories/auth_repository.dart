import '../models/auth_models.dart';

/// Contract for all authentication operations.
///
/// Implementations:
/// - [MockAuthRepository]  — deterministic in-memory mock for development.
/// - [LiveAuthRepository]  — calls the real backend (to be added once the
///                           API contract is confirmed with Member 2).
///
/// The provider and screens depend only on this interface, making it
/// straightforward to swap the mock for the live implementation.
abstract interface class AuthRepository {
  /// Registers a new investor account.
  ///
  /// Returns [UserProfile] on success.
  /// Throws [AppException] on failure.
  Future<AuthResult> register(RegisterRequest request);

  /// Signs in an existing user.
  ///
  /// Returns [AuthResult] on success.
  /// Throws [AppException] on failure.
  Future<AuthResult> login(LoginRequest request);

  /// Signs the current user out and clears stored tokens.
  Future<void> logout();

  /// Fetches the current user's profile from the backend.
  ///
  /// Used on app startup to verify the stored token is still valid.
  Future<UserProfile> getCurrentUser();
}
