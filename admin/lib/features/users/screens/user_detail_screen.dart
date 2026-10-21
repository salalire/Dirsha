import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/role_badge.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../models/user_application.dart';
import '../providers/users_provider.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadApplicationById(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.userReviews),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to User Reviews'),
          ),
          const SizedBox(height: 16),

          if (provider.isLoading)
            const LoadingIndicator(message: 'Loading user application…')
          else if (provider.errorMessage != null)
            ErrorState(
              message: provider.errorMessage!,
              onRetry: () => context
                  .read<UsersProvider>()
                  .loadApplicationById(widget.userId),
            )
          else if (provider.selectedApplication == null)
            const ErrorState(
              message: 'User application not found.\n\n'
                  'The backend may return the same response for a record '
                  'that does not exist and one that is not accessible to '
                  'your role. Verify the ID and your permissions.',
            )
          else
            _UserDetailContent(application: provider.selectedApplication!),

          if (provider.submitSuccess != null)
            _FeedbackBanner(message: provider.submitSuccess!, isError: false),
          if (provider.submitError != null)
            _FeedbackBanner(message: provider.submitError!, isError: true),
        ],
      ),
    );
  }
}

class _UserDetailContent extends StatelessWidget {
  const _UserDetailContent({required this.application});
  final UserApplication application;

  bool get _canReview =>
      application.status == UserApplicationStatus.pending ||
      application.status == UserApplicationStatus.underReview;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                application.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _applicationStatusBadge(application.status),
          ],
        ),
        const SizedBox(height: 4),
        Text('Application ID: ${application.id}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // ── Applicant information ──────────────────────────────────────────
        InfoCard(
          title: 'APPLICANT INFORMATION',
          children: [
            InfoRow(label: 'Full Name', value: application.displayName),
            InfoRow(label: 'Email Address', value: application.email),
            InfoRow(label: 'Application ID', value: application.id),
            InfoRow(
                label: 'Submitted',
                value: _formatDate(application.submittedAt)),
            if (application.reviewedAt != null)
              InfoRow(
                  label: 'Reviewed',
                  value: _formatDate(application.reviewedAt)),
            if (application.reviewNotes != null)
              InfoRow(
                  label: 'Review Notes', value: application.reviewNotes!),
          ],
        ),
        const SizedBox(height: 16),

        // ── Account details ── three separate fields per business rules ────
        InfoCard(
          title: 'ACCOUNT DETAILS',
          children: [
            // Role
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 180,
                    child: Text('Role',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  RoleBadge(role: application.role),
                ],
              ),
            ),
            // Account status — separate from role
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 180,
                    child: Text('Account Status',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  AccountStatusBadge(
                      accountStatus: application.accountStatus),
                ],
              ),
            ),
            // Verification status — separate from account status
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 180,
                    child: Text('Verification Status',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  VerificationStatusBadge(
                      verificationStatus: application.verificationStatus),
                ],
              ),
            ),
            // Explicit note: verification is not a regulated KYC process
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                '⚠️  No regulated identity-verification process exists yet. '
                'Verification status is informational only (B3 pending).',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Review actions ─────────────────────────────────────────────────
        if (_canReview) ...[
          const Text(
            'Review Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Backend authorization enforces whether this action is permitted. '
            'A visible button does not guarantee the action will succeed.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleApprove(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleReject(context),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
              if (provider.isSubmitting) ...[
                const SizedBox(width: 16),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Approve User Application',
      content: 'Approve the application for "${application.displayName}"?\n\n'
          'This action will be recorded by the backend.',
      confirmLabel: 'Approve',
      reasonFieldLabel: 'Notes (optional)',
      onConfirm: (reason) =>
          context.read<UsersProvider>().approve(application.id, notes: reason),
    );
    if (context.mounted) context.read<UsersProvider>().clearFeedback();
  }

  Future<void> _handleReject(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Reject User Application',
      content:
          'Reject the application for "${application.displayName}"?\n\n'
          'Please provide a reason so the applicant knows what to correct.',
      confirmLabel: 'Reject',
      isDestructive: true,
      reasonFieldLabel: 'Reason for rejection',
      reasonRequired: true,
      onConfirm: (reason) => context
          .read<UsersProvider>()
          .reject(application.id, reason: reason ?? ''),
    );
    if (context.mounted) context.read<UsersProvider>().clearFeedback();
  }

  Widget _applicationStatusBadge(UserApplicationStatus status) {
    switch (status) {
      case UserApplicationStatus.pending:
        return StatusBadge.pending();
      case UserApplicationStatus.underReview:
        return StatusBadge.underReview();
      case UserApplicationStatus.approved:
        return StatusBadge.approved();
      case UserApplicationStatus.rejected:
        return StatusBadge.rejected();
      case UserApplicationStatus.suspended:
        return StatusBadge.suspended();
    }
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isError ? AppColors.error : AppColors.success),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: isError ? AppColors.error : AppColors.success),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 13,
                      color: isError ? AppColors.error : AppColors.success))),
        ],
      ),
    );
  }
}
