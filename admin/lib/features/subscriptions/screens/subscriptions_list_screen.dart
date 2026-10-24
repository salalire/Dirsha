import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/etb_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/subscription_model.dart';
import '../providers/subscriptions_provider.dart';

class SubscriptionsListScreen extends StatefulWidget {
  const SubscriptionsListScreen({super.key});

  @override
  State<SubscriptionsListScreen> createState() =>
      _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState extends State<SubscriptionsListScreen> {
  String _searchQuery = '';
  AdminSubscriptionStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionsProvider>().loadSubscriptions();
    });
  }

  List<AdminSubscription> _filter(List<AdminSubscription> list) {
    return list.where((sub) {
      final matchesStatus =
          _filterStatus == null || sub.status == _filterStatus;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          sub.offeringTitle.toLowerCase().contains(q) ||
          sub.symbol.toLowerCase().contains(q) ||
          sub.companyName.toLowerCase().contains(q) ||
          sub.investorName.toLowerCase().contains(q) ||
          sub.investorEmail.toLowerCase().contains(q) ||
          sub.id.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionsProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _filter(provider.subscriptions);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Description
            Text(
              'Subscription Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Audit investor subscription reservations, monitor share allocation results, and inspect escrow settlement.',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 24),

            // Top Summary KPI Cards
            Row(
              children: [
                _buildKpiCard(
                  context,
                  title: 'Total Subscriptions',
                  value: '${provider.totalSubscriptions}',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.info,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  context,
                  title: 'Requested Shares',
                  value: _formatNumber(provider.totalRequestedShares),
                  icon: Icons.how_to_vote_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  context,
                  title: 'Allocated Shares',
                  value: _formatNumber(provider.totalAllocatedShares),
                  icon: Icons.pie_chart_outline,
                  color: AppColors.success,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  context,
                  title: 'Committed Volume',
                  value: EtbFormatter.formatSantim(
                      provider.totalCommittedValueMinor),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by offering, symbol, investor name, email, or ID…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: DropdownButton<AdminSubscriptionStatus?>(
                          value: _filterStatus,
                          hint: const Text('All Statuses'),
                          borderRadius: BorderRadius.circular(8),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Statuses'),
                            ),
                            ...AdminSubscriptionStatus.values.map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterStatus = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () => context
                          .read<SubscriptionsProvider>()
                          .loadSubscriptions(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Content Table
            if (provider.isLoading && provider.subscriptions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingIndicator(message: 'Loading subscriptions…'),
              )
            else if (provider.errorMessage != null &&
                provider.subscriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ErrorState(
                  message: provider.errorMessage!,
                  onRetry: () => context
                      .read<SubscriptionsProvider>()
                      .loadSubscriptions(),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No subscriptions found',
                  subtitle: _searchQuery.isNotEmpty || _filterStatus != null
                      ? 'No subscriptions match your current filter parameters.'
                      : 'No investor subscriptions have been recorded yet.',
                ),
              )
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 68,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(label: Text('Subscription ID')),
                      DataColumn(label: Text('IPO Offering')),
                      DataColumn(label: Text('Investor')),
                      DataColumn(label: Text('Requested')),
                      DataColumn(label: Text('Allocated')),
                      DataColumn(label: Text('Committed Amount')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Created Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((sub) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              sub.id.length > 12
                                  ? '${sub.id.substring(0, 10)}…'
                                  : sub.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sub.offeringTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                if (sub.symbol.isNotEmpty)
                                  Text(
                                    sub.symbol,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withAlpha(140),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sub.investorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  sub.investorEmail,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text('${sub.quantity} shares')),
                          DataCell(
                            sub.isSettled
                                ? Text(
                                    '${sub.allocatedQuantity} shares',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: sub.allocatedQuantity > 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  )
                                : const Text('— (Pending Allocation)'),
                          ),
                          DataCell(
                            Text(
                              EtbFormatter.formatSantim(sub.totalAmountMinor),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(_buildStatusBadge(sub.status)),
                          DataCell(
                            Text(
                              '${sub.createdAt.year}-${sub.createdAt.month.toString().padLeft(2, '0')}-${sub.createdAt.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 18),
                              tooltip: 'View Allocation & Audit Detail',
                              onPressed: () =>
                                  _showDetailModal(context, sub),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
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
      ),
    );
  }

  Widget _buildStatusBadge(AdminSubscriptionStatus status) {
    switch (status) {
      case AdminSubscriptionStatus.reserved:
        return const StatusBadge(
          label: 'Reserved',
          color: Color(0xFFFEF3C7),
          textColor: Color(0xFF92400E),
        );
      case AdminSubscriptionStatus.settled:
        return const StatusBadge(
          label: 'Settled',
          color: Color(0xFFDCFCE7),
          textColor: AppColors.success,
        );
      case AdminSubscriptionStatus.cancelled:
        return const StatusBadge(
          label: 'Cancelled',
          color: Color(0xFFF3F4F6),
          textColor: Color(0xFF4B5563),
        );
      case AdminSubscriptionStatus.refunded:
        return const StatusBadge(
          label: 'Refunded',
          color: Color(0xFFFEE2E2),
          textColor: AppColors.error,
        );
    }
  }

  String _formatNumber(int val) {
    final s = val.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    final offset = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _showDetailModal(BuildContext context, AdminSubscription sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.surface,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Subscription & Allocation Detail',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      _buildStatusBadge(sub.status),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Offering & Company
                  _buildSectionHeader('Offering Information'),
                  _buildDetailRow('Offering Title', sub.offeringTitle),
                  if (sub.symbol.isNotEmpty)
                    _buildDetailRow('Ticker Symbol', sub.symbol),
                  if (sub.companyName.isNotEmpty)
                    _buildDetailRow('Company Name', sub.companyName),
                  _buildDetailRow('IPO ID', sub.ipoId, isMonospace: true),
                  const SizedBox(height: 16),

                  // Investor Information
                  _buildSectionHeader('Investor Details'),
                  _buildDetailRow('Full Name', sub.investorName),
                  _buildDetailRow('Email', sub.investorEmail),
                  _buildDetailRow('Investor ID', sub.investorId,
                      isMonospace: true),
                  const SizedBox(height: 16),

                  // Order & Allocation Details
                  _buildSectionHeader('Order & Allocation Ledger'),
                  _buildDetailRow('Requested Quantity', '${sub.quantity} shares'),
                  _buildDetailRow(
                    'Unit Share Price',
                    EtbFormatter.formatSantim(sub.effectivePricePerShareMinor),
                  ),
                  _buildDetailRow(
                    'Reserved Deposit',
                    EtbFormatter.formatSantim(sub.totalAmountMinor),
                  ),
                  _buildDetailRow(
                    'Allocated Shares',
                    sub.isSettled
                        ? '${sub.allocatedQuantity} shares'
                        : 'Pending Allocation',
                  ),
                  if (sub.isSettled) ...[
                    _buildDetailRow(
                      'Settled Share Value',
                      EtbFormatter.formatSantim(sub.allocatedAmountMinor),
                    ),
                    _buildDetailRow(
                      'Released / Refunded Amount',
                      EtbFormatter.formatSantim(sub.unallocatedRefundMinor),
                    ),
                    _buildDetailRow(
                      'Allocation Outcome',
                      sub.isFull
                          ? '100% Fully Allocated'
                          : sub.isPartial
                              ? 'Partial Pro-Rata Allocation'
                              : 'Zero Allocation (Full Refund)',
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Audit & Idempotency
                  _buildSectionHeader('Audit & Idempotency Metadata'),
                  _buildDetailRow('Subscription ID', sub.id, isMonospace: true),
                  _buildDetailRow('Idempotency Key', sub.idempotencyKey,
                      isMonospace: true),
                  _buildDetailRow(
                    'Created At',
                    sub.createdAt.toIso8601String(),
                  ),
                  if (sub.allocatedAt != null)
                    _buildDetailRow(
                      'Allocated At',
                      sub.allocatedAt!.toIso8601String(),
                    ),

                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
