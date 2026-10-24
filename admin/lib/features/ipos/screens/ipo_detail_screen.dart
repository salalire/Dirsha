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
import '../../subscriptions/models/subscription_model.dart';
import '../../subscriptions/repositories/subscription_repository.dart';

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
        ] else if (ipo.isClosable || ipo.isAllocatable) ...[
          Text('Lifecycle Actions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Manage the subscription window and execute allocation of shares to subscribers.',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (ipo.isClosable) ...[
                ElevatedButton.icon(
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _handleClose(context),
                  icon: const Icon(Icons.lock_clock_outlined, size: 18),
                  label: const Text('Close IPO'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning),
                ),
                const SizedBox(width: 12),
              ],
              if (ipo.isAllocatable) ...[
                ElevatedButton.icon(
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _handleAllocate(context),
                  icon: const Icon(Icons.pie_chart_outline, size: 18),
                  label: const Text('Allocate Shares'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 12),
              ],
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
        if (ipo.status == IpoStatus.open ||
            ipo.status == IpoStatus.closed ||
            ipo.status == IpoStatus.allocated ||
            ipo.status == IpoStatus.listed) ...[
          const SizedBox(height: 24),
          _IpoSubscriptionsBreakdown(ipo: ipo),
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

  Future<void> _handleClose(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Close IPO Subscriptions',
      content: 'Close subscription window for "${ipo.offeringTitle}"?\n\n'
          'Investors will no longer be able to submit new subscriptions.',
      confirmLabel: 'Close IPO',
      reasonFieldLabel: 'Reason (optional)',
      onConfirm: (reason) =>
          context.read<IposProvider>().closeIpo(ipo.id, reason: reason),
    );
    if (context.mounted) context.read<IposProvider>().clearFeedback();
  }

  Future<void> _handleAllocate(BuildContext context) async {
    await showConfirmationDialog(
      context,
      title: 'Allocate Shares',
      content: 'Run share allocation for "${ipo.offeringTitle}"?\n\n'
          'Subscriptions will be settled, allocated shares will be recorded, and unallocated funds will be released back to investors.',
      confirmLabel: 'Allocate Shares',
      onConfirm: (_) =>
          context.read<IposProvider>().allocateIpo(ipo.id),
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

class _IpoSubscriptionsBreakdown extends StatefulWidget {
  const _IpoSubscriptionsBreakdown({required this.ipo});
  final IpoApplication ipo;

  @override
  State<_IpoSubscriptionsBreakdown> createState() =>
      _IpoSubscriptionsBreakdownState();
}

class _IpoSubscriptionsBreakdownState
    extends State<_IpoSubscriptionsBreakdown> {
  bool _isLoading = true;
  String? _error;
  List<AdminSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _IpoSubscriptionsBreakdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ipo.id != widget.ipo.id ||
        oldWidget.ipo.status != widget.ipo.status) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = context.read<SubscriptionsRepository>();
      final list = await repo.getSubscriptions(ipoId: widget.ipo.id);
      if (mounted) {
        setState(() {
          _subscriptions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final totalRequested =
        _subscriptions.fold(0, (sum, s) => sum + s.quantity);
    final totalAllocated =
        _subscriptions.fold(0, (sum, s) => sum + s.allocatedQuantity);
    final offered = widget.ipo.totalSharesOffered ?? 0;
    final oversubRatio = offered > 0 ? (totalRequested / offered) * 100.0 : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscriptions & Allocation Oversight (FR-ALC-01..03)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monitor subscriber demand, allocation ratios, and escrow settlement status.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh Subscriptions',
                  onPressed: _load,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildMiniMetric(
                  context,
                  'Subscribers',
                  '${_subscriptions.length}',
                  Icons.people_outline,
                  AppColors.info,
                ),
                const SizedBox(width: 12),
                _buildMiniMetric(
                  context,
                  'Requested Shares',
                  '$totalRequested',
                  Icons.how_to_vote_outlined,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildMiniMetric(
                  context,
                  'Oversubscription',
                  '${oversubRatio.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  oversubRatio >= 100 ? AppColors.accent : AppColors.primaryLight,
                ),
                const SizedBox(width: 12),
                _buildMiniMetric(
                  context,
                  'Allocated Shares',
                  '$totalAllocated',
                  Icons.pie_chart_outline,
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingIndicator(message: 'Loading subscriptions…'),
              )
            else if (_error != null)
              ErrorState(
                message: _error!,
                onRetry: _load,
              )
            else if (_subscriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No investor subscriptions have been submitted for this IPO yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withAlpha(160),
                    ),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 68,
                  headingRowColor: WidgetStateProperty.all(
                    isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(label: Text('Investor')),
                    DataColumn(label: Text('Requested')),
                    DataColumn(label: Text('Allocated')),
                    DataColumn(label: Text('Committed Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Refund / Release')),
                  ],
                  rows: _subscriptions.map((sub) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(sub.investorName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              Text(sub.investorEmail,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withAlpha(140))),
                            ],
                          ),
                        ),
                        DataCell(Text('${sub.quantity} shares')),
                        DataCell(
                          Text(
                            sub.isSettled
                                ? '${sub.allocatedQuantity} shares'
                                : 'Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: sub.isSettled
                                  ? (sub.allocatedQuantity > 0
                                      ? AppColors.success
                                      : AppColors.error)
                                  : null,
                            ),
                          ),
                        ),
                        DataCell(Text(
                            EtbFormatter.formatSantim(sub.totalAmountMinor))),
                        DataCell(
                          StatusBadge(
                            label: sub.status.label,
                            color: sub.isSettled
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            textColor: sub.isSettled
                                ? AppColors.success
                                : const Color(0xFF92400E),
                          ),
                        ),
                        DataCell(
                          sub.isSettled && sub.unallocatedQuantity > 0
                              ? Text(
                                  'Refunded: ${EtbFormatter.formatSantim(sub.unallocatedRefundMinor)}',
                                  style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                )
                              : sub.isSettled
                                  ? const Text('Fully Settled',
                                      style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11))
                                  : const Text('In Escrow',
                                      style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(160),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

