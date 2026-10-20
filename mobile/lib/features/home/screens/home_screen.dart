import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ipos/models/ipo_models.dart';
import '../../ipos/providers/ipo_provider.dart';
import '../../wallet/providers/wallet_provider.dart';

/// Investor dashboard — the main landing screen after sign-in.
///
/// Wallet balance card + quick IPO list entry point.
/// All data is sourced from [WalletProvider] and [IpoListProvider].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Public so child tabs can request a tab switch without using
  // the protected setState directly.
  void switchTab(int index) => setState(() => _selectedIndex = index);

  static const _tabs = ['Dashboard', 'IPOs', 'Wallet'];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.business_center_outlined,
    Icons.account_balance_wallet_outlined,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
      context.read<IpoListProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [_DashboardTab(), _IposTab(), _WalletTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: List.generate(
          _tabs.length,
          (i) => NavigationDestination(icon: Icon(_icons[i]), label: _tabs[i]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard tab
// ---------------------------------------------------------------------------

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.secondaryEmerald,
        backgroundColor: AppColors.cardSurface,
        onRefresh: () async {
          await Future.wait([
            context.read<WalletProvider>().refresh(),
            context.read<IpoListProvider>().refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (AppConfig.useMockRepositories && !AppConfig.isProduction)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: MockDataBanner(detail: 'Dashboard using mock data'),
                ),
              const SizedBox(height: 24),
              _buildGreeting(user?.firstName),
              const SizedBox(height: 20),
              _WalletSummaryCard(),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'IPO Opportunities',
                actionLabel: 'See all',
                onAction: () {
                  // Switch to IPOs tab
                  final homeState = context
                      .findAncestorStateOfType<_HomeScreenState>();
                  homeState?.switchTab(1);
                },
              ),
              const SizedBox(height: 12),
              _IpoPreviewList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(String? firstName) {
    final name = (firstName != null && firstName.isNotEmpty)
        ? firstName
        : 'Investor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello, $name', style: AppTextStyles.screenTitle),
        const SizedBox(height: 4),
        Text(
          'Here\'s your investment overview.',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet summary card (compact, for dashboard)
// ---------------------------------------------------------------------------

class _WalletSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        if (provider.isSummaryLoading) {
          return const SkeletonCard(height: 120);
        }

        if (provider.summaryError != null) {
          return GestureDetector(
            onTap: provider.refresh,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Could not load wallet balance. Tap to retry.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = provider.summary;
        if (summary == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            final homeState = context
                .findAncestorStateOfType<_HomeScreenState>();
            homeState?.switchTab(2);
          },
          child: Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wallet balance',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(
                    summary.availableBalance,
                    symbol: summary.currency,
                  ),
                  style: AppTextStyles.financialLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _CompactBadge(
                      label: 'Available',
                      value: Formatters.currency(
                        summary.availableBalance,
                        symbol: '',
                      ),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 16),
                    _CompactBadge(
                      label: 'Reserved',
                      value: Formatters.currency(
                        summary.reservedBalance,
                        symbol: '',
                      ),
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $value',
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// IPO preview list (max 3 items, for dashboard)
// ---------------------------------------------------------------------------

class _IpoPreviewList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<IpoListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.hasLoaded) {
          return Column(
            children: List.generate(
              2,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SkeletonCard(height: 88),
              ),
            ),
          );
        }
        if (provider.error != null) {
          return ErrorState(error: provider.error!, onRetry: provider.refresh);
        }
        if (provider.isEmpty) {
          return const EmptyState(
            title: 'No offerings yet',
            message: 'IPO opportunities will appear here.',
            icon: Icons.business_center_outlined,
          );
        }
        final preview = provider.ipos.take(3).toList();
        return Column(
          children: preview
              .map(
                (ipo) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompactIpoRow(
                    ipo: ipo,
                    onTap: () => context.push('/ipos/${ipo.id}'),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CompactIpoRow extends StatelessWidget {
  const _CompactIpoRow({required this.ipo, required this.onTap});
  final IpoSummary ipo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandEmerald,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  ipo.companyName.isNotEmpty
                      ? ipo.companyName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ipo.companyName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.currency(
                      ipo.pricePerShare,
                      symbol: ipo.currency,
                    ),
                    style: AppTextStyles.financialSmall,
                  ),
                ],
              ),
            ),
            StatusBadge.fromString(ipo.status),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// IPOs tab — full list (reuses the IpoListScreen content inline)
// ---------------------------------------------------------------------------

class _IposTab extends StatefulWidget {
  const _IposTab();

  @override
  State<_IposTab> createState() => _IposTabState();
}

class _IposTabState extends State<_IposTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IpoListProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('IPO Offerings', style: AppTextStyles.screenTitle),
            ),
          ),
          if (AppConfig.useMockRepositories && !AppConfig.isProduction)
            const MockDataBanner(detail: 'Mock IPOs — not real offerings'),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<IpoListProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && !provider.hasLoaded) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, _) => const SkeletonCard(height: 130),
                  );
                }
                if (provider.error != null && !provider.hasLoaded) {
                  return ErrorState(
                    error: provider.error!,
                    onRetry: provider.refresh,
                  );
                }
                if (provider.isEmpty) {
                  return const EmptyState(
                    title: 'No offerings available',
                    message: 'Check back later for new IPO opportunities.',
                    icon: Icons.business_center_outlined,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.secondaryEmerald,
                  backgroundColor: AppColors.cardSurface,
                  onRefresh: provider.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.ipos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ipo = provider.ipos[index];
                      return GestureDetector(
                        onTap: () => context.push('/ipos/${ipo.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.brandEmerald,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    ipo.companyName.isNotEmpty
                                        ? ipo.companyName[0].toUpperCase()
                                        : '?',
                                    style: AppTextStyles.cardTitle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ipo.companyName,
                                      style: AppTextStyles.cardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      Formatters.currency(
                                        ipo.pricePerShare,
                                        symbol: ipo.currency,
                                      ),
                                      style: AppTextStyles.financialSmall,
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge.fromString(ipo.status),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet tab — redirects to the full wallet screen inline
// ---------------------------------------------------------------------------

class _WalletTab extends StatefulWidget {
  const _WalletTab();

  @override
  State<_WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<_WalletTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Import wallet screen directly
    return const _InlineWalletView();
  }
}

class _InlineWalletView extends StatelessWidget {
  const _InlineWalletView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Wallet', style: AppTextStyles.screenTitle),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Sign out',
                      message: 'Are you sure you want to sign out?',
                      confirmLabel: 'Sign out',
                      isDangerous: true,
                    );
                    if (confirmed == true && context.mounted) {
                      await context.read<AuthProvider>().logout();
                    }
                  },
                ),
              ],
            ),
          ),
          if (AppConfig.useMockRepositories && !AppConfig.isProduction)
            const MockDataBanner(
              detail: 'Simulated test funds — not a real balance',
            ),
          Expanded(
            child: Consumer<WalletProvider>(
              builder: (context, provider, _) {
                return RefreshIndicator(
                  color: AppColors.secondaryEmerald,
                  backgroundColor: AppColors.cardSurface,
                  onRefresh: provider.refresh,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _WalletBalanceCardFull(provider: provider),
                              const SizedBox(height: 24),
                              const SectionHeader(title: 'Transaction history'),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      _TransactionSliverList(provider: provider),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCardFull extends StatelessWidget {
  const _WalletBalanceCardFull({required this.provider});
  final WalletProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isSummaryLoading) return const SkeletonCard(height: 160);
    if (provider.summaryError != null) {
      return ErrorState(
        error: provider.summaryError!,
        onRetry: provider.refresh,
      );
    }
    final s = provider.summary;
    if (s == null) return const SizedBox.shrink();

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
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(s.totalBalance, symbol: s.currency),
            style: AppTextStyles.balanceHero,
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalancePair(
                  label: 'Available',
                  amount: Formatters.currency(
                    s.availableBalance,
                    symbol: s.currency,
                  ),
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BalancePair(
                  label: 'Reserved',
                  amount: Formatters.currency(
                    s.reservedBalance,
                    symbol: s.currency,
                  ),
                  color: AppColors.warning,
                  icon: Icons.lock_clock_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Deposits and withdrawals are not available in Phase 1.',
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
  }
}

class _BalancePair extends StatelessWidget {
  const _BalancePair({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

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
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
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

class _TransactionSliverList extends StatelessWidget {
  const _TransactionSliverList({required this.provider});
  final WalletProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isTransactionsLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
        final tx = provider.transactions[index];
        final amountSign = tx.isDebit ? '-' : '+';
        final amountColor = tx.isDebit ? AppColors.error : AppColors.success;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Container(
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
                        tx.description ?? tx.type,
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
                  style: AppTextStyles.financialSmall.copyWith(
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: provider.transactions.length),
    );
  }
}
