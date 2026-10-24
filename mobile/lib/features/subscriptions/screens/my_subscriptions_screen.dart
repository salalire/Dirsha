import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';
import 'subscription_detail_screen.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Reserved, 2: Allocated, 3: Released

  static const _filterLabels = [
    'All',
    'Awaiting Allocation',
    'Allocated',
    'Refunded/Released',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('My Subscriptions', style: AppTextStyles.cardTitle),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterLabels.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isSelected = _selectedFilterIndex == i;
                  return ChoiceChip(
                    label: Text(_filterLabels[i]),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilterIndex = i);
                      }
                    },
                    selectedColor: AppColors.brandEmerald,
                    backgroundColor: AppColors.cardSurface,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.secondaryEmerald
                          : AppColors.cardElevated,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading && provider.subscriptions.isEmpty) {
                    return const LoadingIndicator.inline(
                        message: 'Loading subscriptions…');
                  }

                  if (provider.error != null &&
                      provider.subscriptions.isEmpty) {
                    return ErrorState(
                      error: provider.error!,
                      onRetry: () =>
                          context.read<SubscriptionProvider>().refresh(),
                    );
                  }

                  var list = provider.subscriptions;
                  if (_selectedFilterIndex == 1) {
                    list = list
                        .where((s) => s.status == SubscriptionStatus.reserved)
                        .toList();
                  } else if (_selectedFilterIndex == 2) {
                    list = list
                        .where((s) =>
                            s.status == SubscriptionStatus.allocated ||
                            s.status == SubscriptionStatus.partiallyAllocated)
                        .toList();
                  } else if (_selectedFilterIndex == 3) {
                    list = list
                        .where((s) =>
                            s.status == SubscriptionStatus.released ||
                            s.status == SubscriptionStatus.cancelled)
                        .toList();
                  }

                  if (list.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.secondaryEmerald,
                      backgroundColor: AppColors.cardSurface,
                      onRefresh: () =>
                          context.read<SubscriptionProvider>().refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No subscriptions found',
                              message: _selectedFilterIndex == 0
                                  ? 'You have not submitted any IPO subscriptions yet.\n'
                                      'Browse open IPOs to get started.'
                                  : 'No subscriptions match the selected status.',
                              actionLabel: _selectedFilterIndex == 0
                                  ? 'Browse IPOs'
                                  : null,
                              onAction: _selectedFilterIndex == 0
                                  ? () => context.go('/home')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.secondaryEmerald,
                    backgroundColor: AppColors.cardSurface,
                    onRefresh: () =>
                        context.read<SubscriptionProvider>().refresh(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final sub = list[i];
                        return _SubscriptionListItem(
                          subscription: sub,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionDetailScreen(
                                  subscriptionId: sub.id,
                                  initialSubscription: sub,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionListItem extends StatelessWidget {
  const _SubscriptionListItem({
    required this.subscription,
    required this.onTap,
  });

  final SubscriptionModel subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardElevated,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.companyName ??
                                subscription.ipoTitle ??
                                'IPO Subscription',
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Requested: ${subscription.quantity} shares • ${Formatters.money(Money(subscription.amountMinor))}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: subscription.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.cardElevated, height: 1),
                const SizedBox(height: 10),

                // Allocation outcome row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getAllocationIcon(subscription.status),
                          size: 15,
                          color: _getAllocationColor(subscription.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getAllocationSummary(subscription),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getAllocationColor(subscription.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Formatters.dateShort(subscription.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAllocationIcon(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.allocated:
        return Icons.check_circle_outline_rounded;
      case SubscriptionStatus.partiallyAllocated:
        return Icons.pie_chart_outline_rounded;
      case SubscriptionStatus.released:
        return Icons.replay_rounded;
      case SubscriptionStatus.cancelled:
        return Icons.cancel_outlined;
      case SubscriptionStatus.reserved:
      case SubscriptionStatus.unknown:
        return Icons.hourglass_top_rounded;
    }
  }

  Color _getAllocationColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.allocated:
        return AppColors.secondaryEmerald;
      case SubscriptionStatus.partiallyAllocated:
        return Colors.tealAccent;
      case SubscriptionStatus.released:
        return AppColors.gold;
      case SubscriptionStatus.cancelled:
        return Colors.redAccent;
      case SubscriptionStatus.reserved:
      case SubscriptionStatus.unknown:
        return Colors.amber;
    }
  }

  String _getAllocationSummary(SubscriptionModel sub) {
    switch (sub.status) {
      case SubscriptionStatus.allocated:
        return '100% Allocated (${sub.allocatedQuantity} shares)';
      case SubscriptionStatus.partiallyAllocated:
        return 'Allocated: ${sub.allocatedQuantity}/${sub.quantity} shares';
      case SubscriptionStatus.released:
        return 'Not Allocated • 100% Refunded';
      case SubscriptionStatus.cancelled:
        return 'Cancelled • Funds Released';
      case SubscriptionStatus.reserved:
        return 'Funds Reserved • Awaiting Allocation';
      case SubscriptionStatus.unknown:
        return 'Status Unknown';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case SubscriptionStatus.reserved:
        bg = Colors.amber.withAlpha(30);
        fg = Colors.amber;
        label = 'Reserved';
        break;
      case SubscriptionStatus.allocated:
        bg = AppColors.secondaryEmerald.withAlpha(35);
        fg = AppColors.secondaryEmerald;
        label = 'Allocated';
        break;
      case SubscriptionStatus.partiallyAllocated:
        bg = Colors.teal.withAlpha(35);
        fg = Colors.tealAccent;
        label = 'Partial';
        break;
      case SubscriptionStatus.released:
        bg = Colors.blueGrey.withAlpha(40);
        fg = Colors.blueGrey.shade200;
        label = 'Released';
        break;
      case SubscriptionStatus.cancelled:
        bg = Colors.red.withAlpha(30);
        fg = Colors.redAccent;
        label = 'Cancelled';
        break;
      case SubscriptionStatus.unknown:
        bg = AppColors.cardElevated;
        fg = AppColors.textSecondary;
        label = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(90), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
