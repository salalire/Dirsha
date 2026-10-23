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
import '../models/broker_application.dart';
import '../providers/brokers_provider.dart';

class BrokerDetailScreen extends StatefulWidget {
  const BrokerDetailScreen({super.key, required this.brokerId});
  final String brokerId;

  @override
  State<BrokerDetailScreen> createState() => _BrokerDetailScreenState();
}

class _BrokerDetailScreenState extends State<BrokerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrokersProvider>().loadApplicationById(widget.brokerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrokersProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.brokerReviews),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to Broker Reviews'),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const LoadingIndicator(message: 'Loading broker application…')
          else if (provider.errorMessage != null)
            ErrorState(
              message: provider.errorMessage!,
              onRetry: () => context
                  .read<BrokersProvider>()
                  .loadApplicationById(widget.brokerId),
            )
          else if (provider.selectedApplication == null)
            const ErrorState(message: 'Broker application not found.')
          else
            _BrokerDetailContent(
                application: provider.selectedApplication!),
          if (provider.submitSuccess != null)
            _FeedbackBanner(
              message: provider.submitSuccess!,
              isError: false,
              onDismiss: () => context.read<BrokersProvider>().clearFeedback(),
            ),
          if (provider.submitError != null)
            _FeedbackBanner(
              message: provider.submitError!,
              isError: true,
              onDismiss: () => context.read<BrokersProvider>().clearFeedback(),
            ),
        ],
      ),
    );
  }
}

class _BrokerDetailContent extends StatelessWidget {
  const _BrokerDetailContent({required this.application});
  final BrokerApplication application;

  bool get _canReview =>
      application.status == BrokerApplicationStatus.pending ||
      application.status == BrokerApplicationStatus.underReview ||
      application.status == BrokerApplicationStatus.additionalInfoRequired;

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrokersProvider>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(application.displayName,
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
          title: 'BROKER IDENTITY & PROFILE',
          children: [
            InfoRow(
                label: 'Applicant Type',
                value: application.brokerType == 'firm'
                    ? 'Brokerage Firm'
                    : 'Individual Broker'),
            if (application.firmName != null)
              InfoRow(label: 'Firm Name', value: application.firmName!),
            InfoRow(
                label: 'Applicant / Rep Name',
                value: application.applicantName),
            InfoRow(
                label: 'Professional Email',
                value: application.applicantEmail),
            if (application.businessPhone != null)
              InfoRow(label: 'Business Phone', value: application.businessPhone!),
            if (application.businessAddress != null)
              InfoRow(
                  label: 'Business Address',
                  value: application.businessAddress!),
            InfoRow(label: 'Jurisdiction', value: application.jurisdiction),
          ],
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'LICENSING & REGULATORY COMPLIANCE',
          children: [
            InfoRow(label: 'License Number', value: application.licenseNumber),
            InfoRow(
                label: 'Licensing Authority',
                value: application.licenseAuthority),
            InfoRow(
                label: 'License Expiry Date',
                value: _fmt(application.licenseExpiryDate)),
            InfoRow(
              label: 'License Status',
              value: application.isLicenseExpired ? 'EXPIRED' : 'VALID',
            ),
            if (application.isLicenseExpired)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDC2626)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WARNING: License has expired. The application cannot be approved until a valid license is supplied.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'APPLICATION TIMELINE & STATUS',
          children: [
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
                  .map((doc) => _BrokerDocumentRow(doc: doc))
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
                onPressed: provider.isSubmitting || application.isLicenseExpired
                    ? null
                    : () => _handleApprove(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve Broker'),
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
      title: 'Approve Broker Application',
      content:
          'Approve the broker application for "${application.displayName}"?\n\n'
          'This action grants broker privileges to the applicant.',
      confirmLabel: 'Approve',
      reasonFieldLabel: 'Notes (optional)',
      onConfirm: (reason) => context
          .read<BrokersProvider>()
          .approve(application.id, notes: reason),
    );
  }

  Future<void> _handleRequestInfo(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Request Additional Information',
      content:
          'Request corrections or updated documents from "${application.displayName}".\n\n'
          'The applicant will be notified to update and resubmit.',
      confirmLabel: 'Send Request',
      reasonFieldLabel: 'Details of requested information / documents',
      reasonRequired: true,
      onConfirm: (message) => context
          .read<BrokersProvider>()
          .requestAdditionalInfo(application.id, message: message ?? ''),
    );
  }

  Future<void> _handleReject(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Reject Broker Application',
      content:
          'Reject the broker application for "${application.displayName}"?\n\n'
          'Please provide an official reason for rejection.',
      confirmLabel: 'Reject',
      isDestructive: true,
      reasonFieldLabel: 'Reason for rejection',
      reasonRequired: true,
      onConfirm: (reason) => context
          .read<BrokersProvider>()
          .reject(application.id, reason: reason ?? ''),
    );
  }

  Widget _statusBadge(BrokerApplicationStatus s) {
    switch (s) {
      case BrokerApplicationStatus.pending:
        return StatusBadge.pending();
      case BrokerApplicationStatus.underReview:
        return StatusBadge.underReview();
      case BrokerApplicationStatus.additionalInfoRequired:
        return StatusBadge.additionalInfoRequired();
      case BrokerApplicationStatus.approved:
        return StatusBadge.approved();
      case BrokerApplicationStatus.rejected:
        return StatusBadge.rejected();
    }
  }
}

class _BrokerDocumentRow extends StatelessWidget {
  const _BrokerDocumentRow({required this.doc});
  final BrokerDocumentMetadata doc;

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
