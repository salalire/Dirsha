import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
    this.initialSubscription,
  });

  final String subscriptionId;
  final SubscriptionModel? initialSubscription;

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  SubscriptionModel? _subscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.initialSubscription;
    if (_subscription == null) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final sub = await context
        .read<SubscriptionProvider>()
        .getSubscriptionDetails(widget.subscriptionId);
    if (mounted) {
      setState(() {
        _subscription = sub;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Allocation Result', style: AppTextStyles.cardTitle),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading && _subscription == null
            ? const LoadingIndicator.fullScreen(message: 'Loading subscription…')
            : _subscription == null
                ? Center(
                    child: Text(
                      'Subscription not found.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOutcomeBanner(_subscription!),
                        const SizedBox(height: 20),
                        _buildShareBreakdownCard(_subscription!),
                        const SizedBox(height: 16),
                        _buildFinancialBreakdownCard(_subscription!),
                        const SizedBox(height: 16),
                        _buildAuditInfoCard(_subscription!),
                        const SizedBox(height: 20),
                        _buildSimulatedFundsNotice(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildOutcomeBanner(SubscriptionModel sub) {
    IconData icon;
    Color color;
    String title;
    String description;

    switch (sub.status) {
      case SubscriptionStatus.allocated:
        icon = Icons.check_circle_rounded;
        color = AppColors.secondaryEmerald;
        title = 'Allocation Successful';
        description =
            'You were fully allocated ${sub.allocatedQuantity} shares in ${sub.companyName ?? sub.ipoTitle ?? "this offering"}. Shares are reflected in your portfolio.';
        break;
      case SubscriptionStatus.partiallyAllocated:
        icon = Icons.pie_chart_rounded;
        color = Colors.tealAccent;
        title = 'Partially Allocated';
        description =
            'Due to high demand, you received ${sub.allocatedQuantity} of ${sub.quantity} requested shares. The unallocated amount of ${Formatters.money(Money(sub.unallocatedRefundMinor))} was refunded to your available balance.';
        break;
      case SubscriptionStatus.released:
        icon = Icons.replay_rounded;
        color = AppColors.gold;
        title = 'Not Allocated • 100% Refunded';
        description =
            'No shares were allocated for this subscription. Your entire reservation of ${Formatters.money(Money(sub.amountMinor))} was released back to your available balance.';
        break;
      case SubscriptionStatus.cancelled:
        icon = Icons.cancel_rounded;
        color = Colors.redAccent;
        title = 'Subscription Cancelled';
        description =
            'This subscription was cancelled. All reserved funds have been returned to your wallet.';
        break;
      case SubscriptionStatus.reserved:
      case SubscriptionStatus.unknown:
        icon = Icons.hourglass_top_rounded;
        color = Colors.amber;
        title = 'Awaiting Allocation';
        description =
            'Your subscription of ${sub.quantity} shares is confirmed. Simulated funds (${Formatters.money(Money(sub.amountMinor))}) are reserved. Final allocation will take place when the IPO subscription window closes.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(90), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareBreakdownCard(SubscriptionModel sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHARES BREAKDOWN',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Requested Quantity', '${sub.quantity} shares'),
          const Divider(color: AppColors.cardElevated, height: 16),
          _detailRow(
            'Allocated Quantity',
            '${sub.allocatedQuantity} shares',
            valueColor: sub.allocatedQuantity > 0
                ? AppColors.secondaryEmerald
                : AppColors.textSecondary,
            isBold: true,
          ),
          const Divider(color: AppColors.cardElevated, height: 16),
          _detailRow(
            'Unallocated Quantity',
            '${sub.unallocatedQuantity} shares',
            valueColor: sub.unallocatedQuantity > 0
                ? AppColors.gold
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBreakdownCard(SubscriptionModel sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIMULATED FINANCIAL SETTLEMENT',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow(
            'Initial Reserved Amount',
            Formatters.money(Money(sub.amountMinor)),
          ),
          const Divider(color: AppColors.cardElevated, height: 16),
          _detailRow(
            'Settled Amount (Invested)',
            Formatters.money(Money(sub.allocatedAmountMinor)),
            valueColor: AppColors.secondaryEmerald,
            isBold: true,
          ),
          const Divider(color: AppColors.cardElevated, height: 16),
          _detailRow(
            'Refunded to Available Balance',
            Formatters.money(Money(sub.unallocatedRefundMinor)),
            valueColor: sub.unallocatedRefundMinor > 0
                ? AppColors.gold
                : AppColors.textSecondary,
            isBold: sub.unallocatedRefundMinor > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditInfoCard(SubscriptionModel sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUDIT & REFERENCE DETAILS',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Subscription ID', sub.id, isMonospace: true),
          const Divider(color: AppColors.cardElevated, height: 16),
          _detailRow('IPO ID', sub.ipoId, isMonospace: true),
          if (sub.reservationLedgerEntryId != null) ...[
            const Divider(color: AppColors.cardElevated, height: 16),
            _detailRow('Ledger Entry ID', sub.reservationLedgerEntryId!,
                isMonospace: true),
          ],
          const Divider(color: AppColors.cardElevated, height: 16),
          _detailRow('Created At', Formatters.dateMedium(sub.createdAt)),
          const Divider(color: AppColors.cardElevated, height: 16),
          _detailRow('Updated At', Formatters.dateMedium(sub.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildSimulatedFundsNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Simulated Funds Prototype: No real money was debited or credited. All share allocations and refunds are part of the Dirsha investment sandbox.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isMonospace
                ? TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: valueColor ?? AppColors.textPrimary,
                  )
                : AppTextStyles.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
          ),
        ),
      ],
    );
  }
}
