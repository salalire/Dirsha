import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/trading_models.dart';
import '../providers/trading_provider.dart';
import '../widgets/order_placement_bottom_sheet.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradingProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TradingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secondary Trading'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryEmerald,
          labelColor: AppColors.textPrimaryOf(context),
          unselectedLabelColor: AppColors.textSecondaryOf(context),
          tabs: const [
            Tab(text: 'Securities'),
            Tab(text: 'Holdings'),
            Tab(text: 'Orders & Trades'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Simulated Market Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.cardElevatedOf(context),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.warningOf(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Simulated ETB matching engine with dual-settlement.',
                      style: AppTextStyles.bodySmallOf(context)
                          .copyWith(fontSize: 11, color: AppColors.warningOf(context)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading && provider.securities.isEmpty) {
                    return const LoadingIndicator.fullScreen(
                      message: 'Loading trading markets…',
                    );
                  }

                  if (provider.error != null && provider.securities.isEmpty) {
                    return ErrorState(
                      error: provider.error!,
                      onRetry: () => context.read<TradingProvider>().load(),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _SecuritiesTab(securities: provider.securities),
                      _HoldingsTab(holdings: provider.holdings),
                      _OrdersAndTradesTab(
                        orders: provider.orders,
                        trades: provider.trades,
                      ),
                    ],
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

// ── Tab 1: Listed Securities ────────────────────────────────────────────────

class _SecuritiesTab extends StatelessWidget {
  const _SecuritiesTab({required this.securities});
  final List<TradableSecurity> securities;

  @override
  Widget build(BuildContext context) {
    if (securities.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<TradingProvider>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: EmptyState(
              icon: Icons.trending_up,
              title: 'No Listed Securities',
              message:
                  'Securities become tradable here once an allocated IPO is listed by platform administrators.',
            ),
          ),
        ),
      );
    }

    final holdings = context.watch<TradingProvider>().holdings;

    return RefreshIndicator(
      onRefresh: () => context.read<TradingProvider>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: securities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = securities[index];
          final matchingHolding = holdings.where((h) => h.ipoId == s.ipoId);
          final userShares = matchingHolding.isNotEmpty
              ? matchingHolding.first.availableQuantity
              : 0;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.symbol,
                          style: AppTextStyles.cardTitleOf(context).copyWith(fontSize: 18),
                        ),
                        Text(
                          s.companyName,
                          style: AppTextStyles.bodySmallOf(context)
                              .copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successSurfaceOf(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.successOf(context)),
                      ),
                      child: Text(
                        'LISTED',
                        style: TextStyle(
                          color: AppColors.successOf(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Market Ref Price',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondaryOf(context))),
                        Text(
                          '${s.referencePriceEtb.toStringAsFixed(2)} ETB',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Market Activity',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondaryOf(context))),
                        Text(
                          '${s.totalTrades} trades · ${s.openOrdersCount} orders',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryEmerald,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: const Text('Buy Shares'),
                        onPressed: () {
                          OrderPlacementBottomSheet.show(
                            context,
                            security: s,
                            initialSide: 'buy',
                            userAvailableShares: userShares,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: const Text('Sell Shares'),
                        onPressed: () {
                          OrderPlacementBottomSheet.show(
                            context,
                            security: s,
                            initialSide: 'sell',
                            userAvailableShares: userShares,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Tab 2: My Holdings ──────────────────────────────────────────────────────

class _HoldingsTab extends StatelessWidget {
  const _HoldingsTab({required this.holdings});
  final List<ShareHolding> holdings;

  @override
  Widget build(BuildContext context) {
    if (holdings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<TradingProvider>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No Tradable Holdings',
              message:
                  'Allocated IPO shares and secondary market purchases will appear here.',
            ),
          ),
        ),
      );
    }

    final securities = context.watch<TradingProvider>().securities;

    return RefreshIndicator(
      onRefresh: () => context.read<TradingProvider>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: holdings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final h = holdings[index];
          final matchingSec = securities.where((s) => s.ipoId == h.ipoId);
          final sec = matchingSec.isNotEmpty
              ? matchingSec.first
              : TradableSecurity(
                  ipoId: h.ipoId,
                  symbol: h.symbol,
                  companyName: h.companyName,
                  status: 'listed',
                  pricePerShareMinor: h.pricePerShareMinor,
                  totalTrades: 0,
                  openOrdersCount: 0,
                );

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.symbol,
                            style: AppTextStyles.cardTitleOf(context)
                                .copyWith(fontSize: 18)),
                        Text(h.companyName,
                            style: AppTextStyles.bodySmallOf(context)
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                    Text(
                      '${h.quantity} shares',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available: ${h.availableQuantity}  ·  Reserved: ${h.reservedQuantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: h.reservedQuantity > 0
                            ? AppColors.warningOf(context)
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                    Text(
                      'Valuation: ~${h.valuationEtb.toStringAsFixed(2)} ETB',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryEmerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.arrow_downward, size: 14),
                    label: const Text('Sell Available Shares'),
                    onPressed: h.availableQuantity > 0
                        ? () {
                            OrderPlacementBottomSheet.show(
                              context,
                              security: sec,
                              initialSide: 'sell',
                              userAvailableShares: h.availableQuantity,
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Tab 3: Orders & Trades ──────────────────────────────────────────────────

class _OrdersAndTradesTab extends StatelessWidget {
  const _OrdersAndTradesTab({
    required this.orders,
    required this.trades,
  });

  final List<TradeOrder> orders;
  final List<TradeExecution> trades;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty && trades.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<TradingProvider>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders or Executions',
              message:
                  'Active limit orders and executed trades will be tracked here.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TradingProvider>().refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (orders.isNotEmpty) ...[
            Text(
              'ORDERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 8),
            ...orders.map((o) => _OrderCard(order: o)),
            const SizedBox(height: 20),
          ],
          if (trades.isNotEmpty) ...[
            Text(
              'EXECUTED TRADES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 8),
            ...trades.map((t) => _TradeCard(trade: t)),
          ],
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final TradeOrder order;

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == 'buy';
    final statusColor = order.status == 'filled'
        ? AppColors.secondaryEmerald
        : order.status == 'open'
            ? AppColors.warningOf(context)
            : AppColors.textSecondaryOf(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isBuy
                          ? AppColors.successSurfaceOf(context)
                          : AppColors.errorSurfaceOf(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.side.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isBuy ? AppColors.successOf(context) : AppColors.errorOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.filledQuantity}/${order.quantity} shares @ ${order.pricePerShareEtb.toStringAsFixed(2)} ETB',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)),
              ),
              if (order.isCancellable)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorOf(context),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                  ),
                  onPressed: () async {
                    final ok = await context
                        .read<TradingProvider>()
                        .cancelOrder(order.id);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order cancelled successfully'),
                          backgroundColor: AppColors.secondaryEmerald,
                        ),
                      );
                    }
                  },
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  const _TradeCard({required this.trade});
  final TradeExecution trade;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${trade.quantity} ${trade.symbol} @ ${trade.pricePerShareEtb.toStringAsFixed(2)} ETB',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              Text(
                '${trade.executedAt.toLocal()}'.split('.')[0],
                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context)),
              ),
            ],
          ),
          Text(
            '${trade.totalAmountEtb.toStringAsFixed(2)} ETB',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryEmerald,
            ),
          ),
        ],
      ),
    );
  }
}
