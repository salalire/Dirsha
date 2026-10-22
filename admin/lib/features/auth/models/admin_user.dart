/// Represents the signed-in admin user returned after authentication.
///
/// Business rules (Member 2 — Oct 20 2026):
/// - Admin accounts are provisioned out-of-band. No self-registration.
/// - The access token contains the user ID only. Role and accountStatus
///   are re-read from the database on every request by the backend.
/// - Suspended admin accounts lose access — enforced server-side.
///
/// The client MUST NOT trust a locally stored role or accountStatus as
/// an authorization check. They are display values only.
///
/// Field names pending final agreement with Member 2's /auth/login contract.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.accountStatus = 'active',
  });

  final String id;
  final String email;
  final String displayName;

  /// Role from backend. Expected values: 'admin', 'super_admin'.
  /// DISPLAY ONLY — backend re-validates role on every request.
  /// Do not use this as a security gate on the client.
  final String role;

  /// Account status from backend. Expected values: 'active', 'suspended'.
  /// DISPLAY ONLY — a suspended admin loses access via backend enforcement,
  /// not via this field. The backend returns 401/403 for suspended accounts.
  ///
  /// NOTE (B12 PENDING): Session length and refresh-token revocation policy
  /// are not yet agreed. Do not assume a specific token lifetime.
  final String accountStatus;

  bool get isActive => accountStatus == 'active';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ??
          json['full_name'] as String? ??
          json['name'] as String? ??
          json['email'] as String,
      role: json['role'] as String? ?? 'admin',
      accountStatus: json['accountStatus'] as String? ??
          json['account_status'] as String? ??
          'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'role': role,
        'accountStatus': accountStatus,
      };
}
