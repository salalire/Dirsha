import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/users/models/user_application.dart';

/// Badge for displaying a user's ROLE.
/// Role, account status, and verification status are separate — do not merge.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return _badge(role.label, _color(role), _textColor(role));
  }

  Color _color(UserRole r) {
    switch (r) {
      case UserRole.admin:
        return const Color(0xFFEDE9FE); // light purple
      case UserRole.investor:
        return const Color(0xFFDEEBFF); // light blue
      case UserRole.companyRep:
        return const Color(0xFFD1FAE5); // light green
      case UserRole.broker:
        return const Color(0xFFFEF3C7); // light amber
      case UserRole.unknown:
        return AppColors.border;
    }
  }

  Color _textColor(UserRole r) {
    switch (r) {
      case UserRole.admin:
        return const Color(0xFF5B21B6);
      case UserRole.investor:
        return AppColors.info;
      case UserRole.companyRep:
        return AppColors.success;
      case UserRole.broker:
        return const Color(0xFF92400E);
      case UserRole.unknown:
        return AppColors.textSecondary;
    }
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

/// Badge for displaying a user's ACCOUNT STATUS (active / suspended).
/// Separate from role and verification status.
class AccountStatusBadge extends StatelessWidget {
  const AccountStatusBadge({super.key, required this.accountStatus});
  final UserAccountStatus accountStatus;

  @override
  Widget build(BuildContext context) {
    switch (accountStatus) {
      case UserAccountStatus.active:
        return _badge('Active', const Color(0xFFDCFCE7), AppColors.success);
      case UserAccountStatus.suspended:
        return _badge('Suspended', const Color(0xFFFEE2E2), AppColors.error);
      case UserAccountStatus.unknown:
        return _badge('Unknown', AppColors.border, AppColors.textSecondary);
    }
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

/// Badge for displaying VERIFICATION STATUS.
///
/// ⚠️  B3 PENDING: Whether verification is required for investing is not yet
/// agreed. This badge is informational only. Do not use it to gate actions.
/// No regulated identity-verification process exists in the system yet.
class VerificationStatusBadge extends StatelessWidget {
  const VerificationStatusBadge({super.key, required this.verificationStatus});
  final UserVerificationStatus verificationStatus;

  @override
  Widget build(BuildContext context) {
    switch (verificationStatus) {
      case UserVerificationStatus.unverified:
        return _badge('Unverified', AppColors.border, AppColors.textSecondary);
      case UserVerificationStatus.pending:
        return _badge(
            'Verification Pending', const Color(0xFFDEEBFF), AppColors.info);
      case UserVerificationStatus.verified:
        return _badge(
            'Verified', const Color(0xFFDCFCE7), AppColors.success);
      case UserVerificationStatus.rejected:
        return _badge(
            'Verification Rejected', const Color(0xFFFEE2E2), AppColors.error);
      case UserVerificationStatus.unknown:
        return _badge('Unknown', AppColors.border, AppColors.textSecondary);
    }
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
