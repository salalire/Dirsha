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
      appBar: AppBar(
        title: Text('My Subscriptions', style: AppTextStyles.cardTitleOf(context)),
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
                    backgroundColor: AppColors.cardSurfaceOf(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.secondaryEmerald
                          : AppColors.borderOf(context),
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
                      backgroundColor: AppColors.cardSurfaceOf(context),
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
                    backgroundColor: AppColors.cardSurfaceOf(context),
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
        color: AppColors.cardSurfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderOf(context),
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
                            style: AppTextStyles.cardTitleOf(context).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Requested: ${subscription.quantity} shares • ${Formatters.money(Money(subscription.amountMinor))}',
                            style: AppTextStyles.bodySmallOf(context).copyWith(
                              color: AppColors.textSecondaryOf(context),
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
                Divider(color: AppColors.borderOf(context), height: 1),
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
                          color: _getAllocationColor(context, subscription.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getAllocationSummary(subscription),
                          style: AppTextStyles.bodySmallOf(context).copyWith(
                            color: _getAllocationColor(context, subscription.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Formatters.dateShort(subscription.createdAt),
                      style: AppTextStyles.bodySmallOf(context).copyWith(
                        color: AppColors.textSecondaryOf(context),
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

  Color _getAllocationColor(BuildContext context, SubscriptionStatus status) {
    final isDark = AppColors.isDark(context);
    switch (status) {
      case SubscriptionStatus.allocated:
        return isDark ? AppColors.secondaryEmerald : const Color(0xFF15803D);
      case SubscriptionStatus.partiallyAllocated:
        return isDark ? Colors.tealAccent : const Color(0xFF0F766E);
      case SubscriptionStatus.released:
        return isDark ? AppColors.gold : const Color(0xFFB45309);
      case SubscriptionStatus.cancelled:
        return isDark ? Colors.redAccent : const Color(0xFFDC2626);
      case SubscriptionStatus.reserved:
      case SubscriptionStatus.unknown:
        return isDark ? Colors.amber : const Color(0xFFB45309);
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

    final isDark = AppColors.isDark(context);
    switch (status) {
      case SubscriptionStatus.reserved:
        bg = isDark ? Colors.amber.withAlpha(30) : const Color(0xFFFEF3C7);
        fg = isDark ? Colors.amber : const Color(0xFFB45309);
        label = 'Reserved';
        break;
      case SubscriptionStatus.allocated:
        bg = isDark ? AppColors.secondaryEmerald.withAlpha(35) : const Color(0xFFDCFCE7);
        fg = isDark ? AppColors.secondaryEmerald : const Color(0xFF15803D);
        label = 'Allocated';
        break;
      case SubscriptionStatus.partiallyAllocated:
        bg = isDark ? Colors.teal.withAlpha(35) : const Color(0xFFCCFBF1);
        fg = isDark ? Colors.tealAccent : const Color(0xFF0F766E);
        label = 'Partial';
        break;
      case SubscriptionStatus.released:
        bg = isDark ? Colors.blueGrey.withAlpha(40) : const Color(0xFFF1F5F9);
        fg = isDark ? Colors.blueGrey.shade200 : const Color(0xFF475569);
        label = 'Released';
        break;
      case SubscriptionStatus.cancelled:
        bg = isDark ? Colors.red.withAlpha(30) : const Color(0xFFFEE2E2);
        fg = isDark ? Colors.redAccent : const Color(0xFFDC2626);
        label = 'Cancelled';
        break;
      case SubscriptionStatus.unknown:
        bg = AppColors.cardElevatedOf(context);
        fg = AppColors.textSecondaryOf(context);
        label = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(isDark ? 90 : 120), width: 0.8),
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
