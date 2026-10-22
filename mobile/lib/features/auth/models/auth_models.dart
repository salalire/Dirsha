/// Auth-related data models for Dirsha.
///
/// Field names and shapes are based on the conceptual API contract in the SRS
/// (Section 8.3). They will be updated to match Member 2's exact response
/// schema once the API specification is finalised.
///
/// Security:
/// - Password fields are NEVER stored in these models after a request completes.
/// - Tokens are stored via [AuthInterceptor] / [FlutterSecureStorage], not here.
/// - No sensitive data is printed via toString().
library;

// ---------------------------------------------------------------------------
// Request bodies
// ---------------------------------------------------------------------------

/// Payload sent to POST /auth/register
class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    this.role = 'investor',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  // Password is used only to build the request map and is not stored.
  final String password;
  final String role;

  Map<String, dynamic> toJson() {
    final trimmedFullName = '$firstName $lastName'.trim();
    return {
      'full_name': trimmedFullName.isNotEmpty ? trimmedFullName : 'User',
      'email': email,
      'password': password,
      if (phone.isNotEmpty) 'phone': phone,
      'role': role.toLowerCase(),
    };
  }
}

/// Payload sent to POST /auth/login
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};

  // Intentionally suppress password from toString().
  @override
  String toString() => 'LoginRequest(email: $email)';
}

// ---------------------------------------------------------------------------
// Response bodies
// ---------------------------------------------------------------------------

/// Tokens returned by login / register / refresh endpoints.
///
/// Tokens are passed to [AuthInterceptor.saveTokens] immediately and then
/// discarded — they are never kept in application state.
class AuthTokens {
  const AuthTokens({required this.accessToken, this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;
    final access = (json['access_token'] ?? json['accessToken']) as String?;
    if (access == null || access.isEmpty) {
      throw const FormatException(
        'AuthTokens.fromJson: missing accessToken in response',
      );
    }
    return AuthTokens(
      accessToken: access,
      refreshToken: (json['refresh_token'] ?? json['refreshToken']) as String?,
    );
  }

  final String accessToken;
  final String? refreshToken;

  // Never print token values.
  @override
  String toString() => 'AuthTokens([redacted])';
}

/// The authenticated user's public profile.
///
/// Returned alongside tokens on login / register and by GET /users/me.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.accountStatus,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;
    final fullName = (json['full_name'] as String?)?.trim() ?? '';
    final firstName = json['firstName'] as String? ??
        (fullName.contains(' ') ? fullName.split(' ').first : fullName);
    final lastName = json['lastName'] as String? ??
        (fullName.contains(' ')
            ? fullName.substring(fullName.indexOf(' ') + 1)
            : '');

    final rawRole = (json['role'] as String?)?.toUpperCase() ?? 'INVESTOR';
    final rawStatus =
        ((json['account_status'] ?? json['accountStatus']) as String?)
            ?.toUpperCase() ??
        'ACTIVE';

    return UserProfile(
      id: (json['id'] as String?) ?? '',
      firstName: firstName,
      lastName: lastName,
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      role: rawRole,
      accountStatus: rawStatus,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  /// Role string from the backend: "INVESTOR", "COMPANY", "BROKER", "ADMIN".
  final String role;

  /// Account status: "ACTIVE", "SUSPENDED", "PENDING_VERIFICATION", etc.
  final String accountStatus;

  final String? avatarUrl;

  String get fullName => '$firstName $lastName'.trim();

  bool get isActive => accountStatus == 'ACTIVE';

  @override
  String toString() =>
      'UserProfile(id: $id, name: $fullName, role: $role, status: $accountStatus)';
}

/// Combined result returned after a successful login or registration.
class AuthResult {
  const AuthResult({required this.tokens, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;
    return AuthResult(
      tokens: AuthTokens.fromJson(json),
      user: UserProfile.fromJson(
        (json['user'] is Map<String, dynamic>)
            ? json['user'] as Map<String, dynamic>
            : json,
      ),
    );
  }

  /// Tokens — use immediately; do not keep in long-lived state.
  final AuthTokens tokens;
  final UserProfile user;
}
