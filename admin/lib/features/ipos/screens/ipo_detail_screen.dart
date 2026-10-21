import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/etb_formatter.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../models/ipo_application.dart';
import '../providers/ipos_provider.dart';

class IpoDetailScreen extends StatefulWidget {
  const IpoDetailScreen({super.key, required this.ipoId});
  final String ipoId;

  @override
  State<IpoDetailScreen> createState() => _IpoDetailScreenState();
}

class _IpoDetailScreenState extends State<IpoDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IposProvider>().loadApplicationById(widget.ipoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IposProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.ipoManagement),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to IPO Management'),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const LoadingIndicator(message: 'Loading IPO application…')
          else if (provider.errorMessage != null)
            ErrorState(
              message: provider.errorMessage!,
              onRetry: () => context
                  .read<IposProvider>()
                  .loadApplicationById(widget.ipoId),
            )
          else if (provider.selectedApplication == null)
            const ErrorState(
              message: 'IPO not found or not accessible.\n\n'
                  'The backend returns the same 404 for an IPO that does not '
                  'exist and one restricted to admin/company_rep access.',
            )
          else
            _IpoDetailContent(ipo: provider.selectedApplication!),
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

class _IpoDetailContent extends StatelessWidget {
  const _IpoDetailContent({required this.ipo});
  final IpoApplication ipo;

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  String _fmtNum(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    final offset = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IposProvider>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + status
        Row(
          children: [
            Expanded(
              child: Text(ipo.offeringTitle,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ),
            _ipoStatusBadge(ipo.status),
          ],
        ),
        const SizedBox(height: 4),
        Text('IPO ID: ${ipo.id}',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(160))),
        const SizedBox(height: 24),

        // Cards
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final cards = [
            InfoCard(
              title: 'OFFERING INFORMATION',
              children: [
                InfoRow(label: 'Offering Title', value: ipo.offeringTitle),
                InfoRow(label: 'Company', value: ipo.companyName),
                InfoRow(label: 'Company ID', value: ipo.companyId),
                InfoRow(label: 'IPO ID', value: ipo.id),
                InfoRow(label: 'Status', value: ipo.status.label),
                InfoRow(label: 'Submitted', value: _fmt(ipo.submittedAt)),
                if (ipo.reviewedAt != null)
                  InfoRow(label: 'Reviewed', value: _fmt(ipo.reviewedAt)),
              ],
            ),
            InfoCard(
              title: 'OFFERING TERMS',
              children: [
                InfoRow(label: 'Open Date', value: _fmt(ipo.openDate)),
                InfoRow(label: 'Close Date', value: _fmt(ipo.closeDate)),
                InfoRow(
                  label: 'Price Per Share',
                  value: EtbFormatter.formatSantimOrFallback(
                      ipo.pricePerShareSantim),
                ),
                InfoRow(
                  label: 'Total Shares Offered',
                  value: ipo.totalSharesOffered != null
                      ? '${_fmtNum(ipo.totalSharesOffered!)} shares'
                      : '— (not provided)',
                ),
              ],
            ),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            );
          }
          return Column(
              children: [cards[0], const SizedBox(height: 16), cards[1]]);
        }),
        const SizedBox(height: 20),

        // Documents
        InfoCard(
          title: 'SUBMITTED DOCUMENTS',
          children: ipo.documents.isEmpty
              ? [
                  Text('No documents submitted.',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withAlpha(160)))
                ]
              : ipo.documents
                  .map((doc) => _DocumentRow(doc: doc))
                  .toList(),
        ),
        const SizedBox(height: 20),

        if (ipo.reviewNotes != null) ...[
          InfoCard(
            title: 'REVIEW NOTES',
            children: [
              Text(ipo.reviewNotes!,
                  style: TextStyle(fontSize: 13, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Review actions
        if (ipo.isReviewable) ...[
          Text('Review Actions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(
            'These actions are recorded and cannot be undone without further review.',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleApprove(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve IPO'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleReject(context),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Reject IPO'),
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
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: cs.onSurface.withAlpha(160)),
                const SizedBox(width: 8),
                Text(
                  'No review actions available. '
                  'Current status: ${ipo.status.label}.',
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface.withAlpha(160)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Approve IPO Application',
      content: 'Approve "${ipo.offeringTitle}"?\n\n'
          'Once approved, the company can open the offering for subscription.',
      confirmLabel: 'Approve IPO',
      reasonFieldLabel: 'Notes (optional)',
      onConfirm: (reason) =>
          context.read<IposProvider>().approve(ipo.id, notes: reason),
    );
    if (context.mounted) context.read<IposProvider>().clearFeedback();
  }

  Future<void> _handleReject(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Reject IPO Application',
      content: 'Reject "${ipo.offeringTitle}"?\n\n'
          'The company will need to address issues and resubmit.',
      confirmLabel: 'Reject IPO',
      isDestructive: true,
      reasonFieldLabel: 'Reason for rejection',
      reasonRequired: true,
      onConfirm: (reason) => context
          .read<IposProvider>()
          .reject(ipo.id, reason: reason ?? ''),
    );
    if (context.mounted) context.read<IposProvider>().clearFeedback();
  }

  Widget _ipoStatusBadge(IpoStatus s) {
    switch (s) {
      case IpoStatus.approved:
        return StatusBadge.approved();
      case IpoStatus.rejected:
        return StatusBadge.rejected();
      case IpoStatus.open:
        return StatusBadge.open();
      case IpoStatus.closed:
        return StatusBadge.closed();
      default:
        return StatusBadge.fromLabel(s.label);
    }
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.doc});
  final IpoDocumentMetadata doc;

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

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
                Text(
                    '${doc.documentType} • Submitted ${_fmt(doc.submittedAt)}',
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
                'Access requires backend authorization (Phase 2).',
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
                    color:
                        isError ? AppColors.error : AppColors.success)),
          ),
        ],
      ),
    );
  }
}
