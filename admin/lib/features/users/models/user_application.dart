library;

/// Represents a user/investor onboarding application awaiting admin review.
///
/// Business rules (Member 2 — Oct 20 2026):
/// Role, account status, and verification status are SEPARATE concepts.
/// Do NOT merge them into a single field.
///
/// role            — what the user can do (investor, company_rep, broker, admin)
/// accountStatus   — whether the account is active or suspended
/// verificationStatus — where the user is in the identity check process
///
/// IMPORTANT — B3 PENDING TEAM SIGN-OFF:
/// Whether identity verification is required before an investor can subscribe
/// is NOT yet decided. Do not imply that verification is implemented or
/// required. Display verificationStatus as-is from the backend without
/// inferring eligibility from it.
///
/// Field names are placeholders pending final agreement with Member 2.
/// Update fromJson() once the /admin/users API contract is confirmed.

// ── Role ──────────────────────────────────────────────────────────────────────
/// Supported roles as defined by Member 2's backend business rules.
/// Backend string values: 'investor', 'company_rep', 'broker', 'admin'
enum UserRole {
  investor,
  companyRep,
  broker,
  admin,
  unknown, // fallback for values not yet in this enum
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.investor:
        return 'Investor';
      case UserRole.companyRep:
        return 'Company Representative';
      case UserRole.broker:
        return 'Broker';
      case UserRole.admin:
        return 'Admin';
      case UserRole.unknown:
        return 'Unknown';
    }
  }
}

// ── Account status ────────────────────────────────────────────────────────────
/// Account status as defined by Member 2's backend business rules.
/// Backend string values: 'active', 'suspended'
/// This is SEPARATE from verification status.
enum UserAccountStatus {
  active,
  suspended,
  unknown,
}

extension UserAccountStatusLabel on UserAccountStatus {
  String get label {
    switch (this) {
      case UserAccountStatus.active:
        return 'Active';
      case UserAccountStatus.suspended:
        return 'Suspended';
      case UserAccountStatus.unknown:
        return 'Unknown';
    }
  }
}

// ── Verification status ───────────────────────────────────────────────────────
/// Verification status as defined by Member 2's backend business rules.
/// Backend string values: 'unverified', 'pending', 'verified', 'rejected'
///
/// ⚠️  B3 PENDING: Whether verification is required for investing has not been
/// agreed. Display this field as information only. Do NOT use it to gate
/// actions or imply that a verified account can do anything an unverified
/// account cannot, until B3 is resolved.
///
/// NOTE: No actual identity-verification process exists in the system yet.
/// 'verified' means the backend has marked the record as verified through
/// whatever mechanism exists — it does NOT mean a regulated KYC process.
enum UserVerificationStatus {
  unverified,
  pending,
  verified,
  rejected,
  unknown,
}

extension UserVerificationStatusLabel on UserVerificationStatus {
  String get label {
    switch (this) {
      case UserVerificationStatus.unverified:
        return 'Unverified';
      case UserVerificationStatus.pending:
        return 'Pending Verification';
      case UserVerificationStatus.verified:
        return 'Verified';
      case UserVerificationStatus.rejected:
        return 'Verification Rejected';
      case UserVerificationStatus.unknown:
        return 'Unknown';
    }
  }
}

// ── Application-level onboarding status ──────────────────────────────────────
/// The onboarding/review workflow status for this application record.
/// This is the status of the admin review process, not the account itself.
/// Backend string values: 'pending', 'under_review', 'approved',
///                        'rejected', 'suspended'
enum UserApplicationStatus {
  pending,
  underReview,
  approved,
  rejected,
  suspended,
}

extension UserApplicationStatusLabel on UserApplicationStatus {
  String get label {
    switch (this) {
      case UserApplicationStatus.pending:
        return 'Pending';
      case UserApplicationStatus.underReview:
        return 'Under Review';
      case UserApplicationStatus.approved:
        return 'Approved';
      case UserApplicationStatus.rejected:
        return 'Rejected';
      case UserApplicationStatus.suspended:
        return 'Suspended';
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class UserApplication {
  const UserApplication({
    required this.id,
    required this.displayName,
    required this.email,
    required this.status,
    required this.submittedAt,
    this.role = UserRole.investor,
    this.accountStatus = UserAccountStatus.active,
    this.verificationStatus = UserVerificationStatus.unverified,
    this.reviewedAt,
    this.reviewNotes,
  });

  final String id;
  final String displayName;
  final String email;

  /// Onboarding/review workflow status. See [UserApplicationStatus].
  final UserApplicationStatus status;

  /// The user's assigned role. Separate from account and verification status.
  final UserRole role;

  /// Whether the account is active or suspended. Separate from role.
  final UserAccountStatus accountStatus;

  /// Where the user is in the verification process.
  /// ⚠️  B3 PENDING — do not use to infer eligibility.
  /// No regulated identity-verification process exists yet.
  final UserVerificationStatus verificationStatus;

  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  factory UserApplication.fromJson(Map<String, dynamic> json) {
    return UserApplication(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ??
          json['full_name'] as String? ??
          json['name'] as String? ??
          'Unknown',
      email: json['email'] as String? ?? '',
      status: _parseApplicationStatus(json['status'] as String? ?? json['verification_status'] as String?),
      role: _parseRole(json['role'] as String?),
      accountStatus: _parseAccountStatus(
          json['accountStatus'] as String? ?? json['account_status'] as String?),
      verificationStatus: _parseVerificationStatus(
          json['verificationStatus'] as String? ?? json['verification_status'] as String?),
      submittedAt: DateTime.tryParse(
              json['submittedAt'] as String? ?? json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      reviewNotes: json['reviewNotes'] as String?,
    );
  }

  static UserApplicationStatus _parseApplicationStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return UserApplicationStatus.pending;
      case 'under_review':
        return UserApplicationStatus.underReview;
      case 'approved':
        return UserApplicationStatus.approved;
      case 'rejected':
        return UserApplicationStatus.rejected;
      case 'suspended':
        return UserApplicationStatus.suspended;
      default:
        return UserApplicationStatus.pending;
    }
  }

  static UserRole _parseRole(String? raw) {
    switch (raw) {
      case 'investor':
        return UserRole.investor;
      case 'company_rep':
        return UserRole.companyRep;
      case 'broker':
        return UserRole.broker;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  static UserAccountStatus _parseAccountStatus(String? raw) {
    switch (raw) {
      case 'active':
        return UserAccountStatus.active;
      case 'suspended':
        return UserAccountStatus.suspended;
      default:
        return UserAccountStatus.unknown;
    }
  }

  static UserVerificationStatus _parseVerificationStatus(String? raw) {
    switch (raw) {
      case 'unverified':
        return UserVerificationStatus.unverified;
      case 'pending':
        return UserVerificationStatus.pending;
      case 'verified':
        return UserVerificationStatus.verified;
      case 'rejected':
        return UserVerificationStatus.rejected;
      default:
        return UserVerificationStatus.unknown;
    }
  }
}
