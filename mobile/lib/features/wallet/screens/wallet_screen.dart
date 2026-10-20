import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/wallet_models.dart';
import '../providers/wallet_provider.dart';

/// Wallet overview screen — balance summary and transaction history.
///
/// Read-only in Phase 1. Deposit/withdrawal functionality is out of scope.
/// All balances shown are sourced from the backend (or explicitly labeled
/// as mock data during development).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        children: [
          if (AppConfig.useMockRepositories && !AppConfig.isProduction)
            const MockDataBanner(
              detail: 'Simulated test funds — not a real account balance',
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryEmerald,
              backgroundColor: AppColors.cardSurface,
              onRefresh: () => context.read<WalletProvider>().refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _WalletBalanceCard(),
                          const SizedBox(height: 24),
                          const SectionHeader(title: 'Transaction history'),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  _TransactionList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        if (provider.isSummaryLoading) {
          return const SkeletonCard(height: 140);
        }
        if (provider.summaryError != null) {
          return ErrorState(
            error: provider.summaryError!,
            onRetry: provider.refresh,
          );
        }
        final summary = provider.summary;
        if (summary == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brandEmerald, AppColors.secondaryEmerald],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total balance',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.currency(
                  summary.totalBalance,
                  symbol: summary.currency,
                ),
                style: AppTextStyles.balanceHero,
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, thickness: 1, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BalanceItem(
                      label: 'Available',
                      amount: Formatters.currency(
                        summary.availableBalance,
                        symbol: summary.currency,
                      ),
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BalanceItem(
                      label: 'Reserved',
                      amount: Formatters.currency(
                        summary.reservedBalance,
                        symbol: summary.currency,
                      ),
                      icon: Icons.lock_clock_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Read-only in Phase 1. Deposits/withdrawals coming later.',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: AppTextStyles.financialSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        if (provider.isTransactionsLoading) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SkeletonCard(height: 72),
              ),
              childCount: 4,
            ),
          );
        }
        if (provider.transactionsError != null) {
          return SliverToBoxAdapter(
            child: ErrorState(
              error: provider.transactionsError!,
              onRetry: provider.refresh,
            ),
          );
        }
        if (provider.transactions.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
              title: 'No transactions yet',
              message: 'Your transaction history will appear here.',
              icon: Icons.receipt_long_outlined,
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index < provider.transactions.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _TransactionRow(tx: provider.transactions[index]),
              );
            }
            return null;
          }, childCount: provider.transactions.length),
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final amountSign = tx.isDebit ? '-' : '+';
    final amountColor = tx.isDebit ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tx.isDebit
                  ? AppColors.errorSurface
                  : AppColors.successSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              tx.isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? _labelFor(tx.type),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    StatusBadge.fromString(tx.status),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.relativeDate(tx.createdAt),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$amountSign${Formatters.currency(tx.amount, symbol: tx.currency)}',
            style: AppTextStyles.financialSmall.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }

  String _labelFor(String type) => switch (type.toUpperCase()) {
    'CREDIT' => 'Funds credited',
    'DEBIT' => 'Funds debited',
    'RESERVATION' => 'Funds reserved',
    'RELEASE' => 'Reservation released',
    'REFUND' => 'Refund received',
    'SETTLEMENT' => 'Settlement',
    _ => type,
  };
}
