import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/holding_card.dart';
import '../widgets/portfolio_summary_card.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();

    if (provider.isLoading && provider.portfolio == null) {
      return const Scaffold(
        body: LoadingIndicator.fullScreen(message: 'Loading portfolio…'),
      );
    }

    if (provider.error != null && provider.portfolio == null) {
      return Scaffold(
        body: SafeArea(
          child: ErrorState(
            error: provider.error!,
            onRetry: () => context.read<PortfolioProvider>().load(),
          ),
        ),
      );
    }

    final summary = provider.summary;
    final holdings = provider.holdings;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondaryEmerald,
          backgroundColor: AppColors.cardSurfaceOf(context),
          onRefresh: () => context.read<PortfolioProvider>().refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary != null) ...[
                  PortfolioSummaryCard(summary: summary),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/trading'),
                    icon: const Icon(Icons.trending_up, size: 16),
                    label: const Text('Trade Shares on Secondary Market'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryEmerald,
                      side: const BorderSide(color: AppColors.secondaryEmerald),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'My Holdings',
                  actionLabel: 'All Subscriptions',
                  onAction: () => context.push('/subscriptions'),
                ),
                const SizedBox(height: 12),
                if (holdings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: EmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'No shareholdings yet',
                      message:
                          'Shares from successfully allocated IPO subscriptions will appear here.\n\n'
                          'Pending subscriptions awaiting allocation can be viewed in Subscriptions.',
                      actionLabel: 'View Subscriptions',
                      onAction: () => context.push('/subscriptions'),
                    ),
                  )
                else
                  ...holdings.map(
                    (holding) => HoldingCard(
                      holding: holding,
                      onTap: () {
                        context.push('/ipos/${holding.ipoId}');
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
