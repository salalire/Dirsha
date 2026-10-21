import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../models/company_application.dart';
import '../providers/companies_provider.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({super.key, required this.companyId});
  final String companyId;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompaniesProvider>().loadApplicationById(widget.companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompaniesProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.companyReviews),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to Company Reviews'),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const LoadingIndicator(message: 'Loading company application…')
          else if (provider.errorMessage != null)
            ErrorState(
              message: provider.errorMessage!,
              onRetry: () => context
                  .read<CompaniesProvider>()
                  .loadApplicationById(widget.companyId),
            )
          else if (provider.selectedApplication == null)
            const ErrorState(message: 'Company application not found.')
          else
            _CompanyDetailContent(
                application: provider.selectedApplication!),
          if (provider.submitSuccess != null)
            _FeedbackBanner(
                message: provider.submitSuccess!, isError: false),
          if (provider.submitError != null)
            _FeedbackBanner(message: provider.submitError!, isError: true),
        ],
      ),
    );
  }
}

class _CompanyDetailContent extends StatelessWidget {
  const _CompanyDetailContent({required this.application});
  final CompanyApplication application;

  bool get _canReview =>
      application.status == CompanyApplicationStatus.pending ||
      application.status == CompanyApplicationStatus.underReview;

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompaniesProvider>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(application.companyName,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ),
            _statusBadge(application.status),
          ],
        ),
        const SizedBox(height: 4),
        Text('Application ID: ${application.id}',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(160))),
        const SizedBox(height: 24),
        InfoCard(
          title: 'COMPANY INFORMATION',
          children: [
            InfoRow(label: 'Company Name', value: application.companyName),
            InfoRow(
                label: 'Representative',
                value: application.representativeName),
            InfoRow(
                label: 'Representative Email',
                value: application.representativeEmail),
            InfoRow(label: 'Application ID', value: application.id),
            InfoRow(
                label: 'Submitted', value: _fmt(application.submittedAt)),
            if (application.reviewedAt != null)
              InfoRow(
                  label: 'Reviewed',
                  value: _fmt(application.reviewedAt)),
            if (application.reviewNotes != null)
              InfoRow(
                  label: 'Review Notes',
                  value: application.reviewNotes!),
          ],
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'SUBMITTED DOCUMENTS',
          children: application.documents.isEmpty
              ? [
                  Text('No documents submitted.',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withAlpha(160)))
                ]
              : application.documents
                  .map((doc) => _DocumentRow(doc: doc))
                  .toList(),
        ),
        const SizedBox(height: 24),
        if (_canReview) ...[
          Text('Review Actions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
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
                        strokeWidth: 2, color: AppColors.primary)),
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
      title: 'Approve Company Application',
      content:
          'Approve the onboarding application for "${application.companyName}"?\n\n'
          'This action will be recorded.',
      confirmLabel: 'Approve',
      reasonFieldLabel: 'Notes (optional)',
      onConfirm: (reason) => context
          .read<CompaniesProvider>()
          .approve(application.id, notes: reason),
    );
    if (context.mounted) context.read<CompaniesProvider>().clearFeedback();
  }

  Future<void> _handleReject(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Reject Company Application',
      content:
          'Reject the onboarding application for "${application.companyName}"?\n\n'
          'Please provide a reason.',
      confirmLabel: 'Reject',
      isDestructive: true,
      reasonFieldLabel: 'Reason for rejection',
      reasonRequired: true,
      onConfirm: (reason) => context
          .read<CompaniesProvider>()
          .reject(application.id, reason: reason ?? ''),
    );
    if (context.mounted) context.read<CompaniesProvider>().clearFeedback();
  }

  Widget _statusBadge(CompanyApplicationStatus s) {
    switch (s) {
      case CompanyApplicationStatus.pending:
        return StatusBadge.pending();
      case CompanyApplicationStatus.underReview:
        return StatusBadge.underReview();
      case CompanyApplicationStatus.approved:
        return StatusBadge.approved();
      case CompanyApplicationStatus.rejected:
        return StatusBadge.rejected();
      case CompanyApplicationStatus.suspended:
        return StatusBadge.suspended();
    }
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.doc});
  final DocumentMetadata doc;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.description_outlined,
              size: 18, color: cs.onSurface.withAlpha(160)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(doc.documentType,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withAlpha(160))),
              ],
            ),
          ),
          StatusBadge.fromLabel(doc.reviewStatus),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Document files are in private storage.\n'
                'Download requires backend authorization (not yet available).',
            child: Icon(Icons.lock_outline,
                size: 16, color: cs.onSurface.withAlpha(160)),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isError
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
        : (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7));
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
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
