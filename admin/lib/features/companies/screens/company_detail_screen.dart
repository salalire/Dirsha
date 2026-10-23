import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/url_launcher.dart';
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
              message: provider.submitSuccess!,
              isError: false,
              onDismiss: () => context.read<CompaniesProvider>().clearFeedback(),
            ),
          if (provider.submitError != null)
            _FeedbackBanner(
              message: provider.submitError!,
              isError: true,
              onDismiss: () => context.read<CompaniesProvider>().clearFeedback(),
            ),
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
      application.status == CompanyApplicationStatus.underReview ||
      application.status == CompanyApplicationStatus.additionalInfoRequired;

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
          title: 'COMPANY IDENTITY & REGISTRATION',
          children: [
            InfoRow(label: 'Company Name', value: application.companyName),
            if (application.registrationNumber != null)
              InfoRow(
                  label: 'Registration Number',
                  value: application.registrationNumber!),
            if (application.tin != null)
              InfoRow(label: 'Tax Identification Number (TIN)', value: application.tin!),
            if (application.legalEntityType != null)
              InfoRow(
                  label: 'Legal Entity Type',
                  value: application.legalEntityType!),
            if (application.sector != null)
              InfoRow(label: 'Sector / Industry', value: application.sector!),
            if (application.businessAddress != null)
              InfoRow(
                  label: 'Registered Address',
                  value: application.businessAddress!),
            if (application.businessEmail != null)
              InfoRow(
                  label: 'Business Email', value: application.businessEmail!),
            if (application.businessPhone != null)
              InfoRow(
                  label: 'Business Phone', value: application.businessPhone!),
            if (application.website != null)
              InfoRow(label: 'Website', value: application.website!),
          ],
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'AUTHORIZED REPRESENTATIVE & APPLICATION STATUS',
          children: [
            InfoRow(
                label: 'Representative Name',
                value: application.representativeName),
            InfoRow(
                label: 'Representative Email',
                value: application.representativeEmail),
            InfoRow(label: 'Application ID', value: application.id),
            InfoRow(
                label: 'Submitted Date', value: _fmt(application.submittedAt)),
            if (application.reviewedAt != null)
              InfoRow(
                  label: 'Reviewed Date',
                  value: _fmt(application.reviewedAt)),
            if (application.reviewNotes != null)
              InfoRow(
                  label: 'Review Notes / Decision Reason',
                  value: application.reviewNotes!),
          ],
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'SUPPORTING DOCUMENTS',
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleApprove(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve Company'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
              ),
              ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleRequestInfo(context),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Request Info'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
              ),
              OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleReject(context),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Reject Application'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
              if (provider.isSubmitting) ...[
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
          'This action verifies the company and enables IPO submission.',
      confirmLabel: 'Approve',
      reasonFieldLabel: 'Notes (optional)',
      onConfirm: (reason) => context
          .read<CompaniesProvider>()
          .approve(application.id, notes: reason),
    );
  }

  Future<void> _handleRequestInfo(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Request Additional Information',
      content:
          'Request corrections or missing documents from "${application.companyName}".\n\n'
          'The applicant will be notified to correct and resubmit their application.',
      confirmLabel: 'Send Request',
      reasonFieldLabel: 'Details of required information / documents',
      reasonRequired: true,
      onConfirm: (message) => context
          .read<CompaniesProvider>()
          .requestAdditionalInfo(application.id, message: message ?? ''),
    );
  }

  Future<void> _handleReject(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Reject Company Application',
      content:
          'Reject the onboarding application for "${application.companyName}"?\n\n'
          'Please provide an official reason for rejection.',
      confirmLabel: 'Reject',
      isDestructive: true,
      reasonFieldLabel: 'Reason for rejection',
      reasonRequired: true,
      onConfirm: (reason) => context
          .read<CompaniesProvider>()
          .reject(application.id, reason: reason ?? ''),
    );
  }

  Widget _statusBadge(CompanyApplicationStatus s) {
    switch (s) {
      case CompanyApplicationStatus.pending:
        return StatusBadge.pending();
      case CompanyApplicationStatus.underReview:
        return StatusBadge.underReview();
      case CompanyApplicationStatus.additionalInfoRequired:
        return StatusBadge.additionalInfoRequired();
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

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _openDocument(BuildContext context) {
    final client = context.read<ApiClient>();
    final token = client.token;
    final tokenParam = token != null && token.isNotEmpty ? '?token=$token' : '';
    final url = '${AppConfig.apiBaseUrl}/admin/documents/${doc.id}$tokenParam';
    openUrlInNewTab(url);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sizeLabel = _formatSize(doc.fileSize);
    final subtitle = [
      doc.documentType,
      if (sizeLabel.isNotEmpty) sizeLabel,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.description_outlined,
              size: 20, color: cs.onSurface.withAlpha(180)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withAlpha(160))),
                if (doc.reviewNotes != null && doc.reviewNotes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Note: ${doc.reviewNotes}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
          StatusBadge.fromLabel(doc.reviewStatus),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _openDocument(context),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('View', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 32),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatefulWidget {
  const _FeedbackBanner({
    required this.message,
    required this.isError,
    this.onDismiss,
  });
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  @override
  State<_FeedbackBanner> createState() => _FeedbackBannerState();
}

class _FeedbackBannerState extends State<_FeedbackBanner> {
  @override
  void initState() {
    super.initState();
    if (!widget.isError && widget.onDismiss != null) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) widget.onDismiss!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.isError
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
        : (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7));
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: widget.isError ? AppColors.error : AppColors.success),
      ),
      child: Row(
        children: [
          Icon(widget.isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: widget.isError ? AppColors.error : AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.isError ? AppColors.error : AppColors.success,
              ),
            ),
          ),
          if (widget.onDismiss != null)
            IconButton(
              icon: Icon(Icons.close,
                  size: 16,
                  color: widget.isError ? AppColors.error : AppColors.success),
              onPressed: widget.onDismiss,
              tooltip: 'Dismiss',
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}
