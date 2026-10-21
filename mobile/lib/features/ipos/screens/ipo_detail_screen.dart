import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/ipo_models.dart';
import '../providers/ipo_provider.dart';

/// Detailed view of a single IPO offering.
///
/// Shows all fields returned by the backend for this offering.
/// The subscription button is present as a planned Phase 2 feature
/// and is clearly disabled with an explanatory label — it does not
/// claim to submit a real subscription.
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
      context.read<IpoDetailProvider>().load(widget.ipoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Consumer<IpoDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const _LoadingDetail();
          }
          if (provider.error != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('IPO Details')),
              body: ErrorState(
                error: provider.error!,
                onRetry: () => provider.refresh(widget.ipoId),
              ),
            );
          }
          if (provider.detail == null) {
            return const Scaffold(body: LoadingIndicator.fullScreen());
          }
          return _DetailContent(detail: provider.detail!);
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final IpoDetail detail;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (AppConfig.useMockRepositories && !AppConfig.isProduction)
                const MockDataBanner(
                  detail: 'Mock IPO detail — not a real offering',
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow(),
                    const SizedBox(height: 20),
                    _buildOfferingTerms(),
                    if (detail.subscriptionStartDate != null ||
                        detail.subscriptionEndDate != null) ...[
                      const SizedBox(height: 16),
                      _buildDates(),
                    ],
                    if (detail.description != null) ...[
                      const SizedBox(height: 24),
                      _buildSection('About this offering', detail.description!),
                    ],
                    if (detail.companyDescription != null) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        'About the company',
                        detail.companyDescription!,
                      ),
                    ],
                    if (detail.riskDisclosure != null) ...[
                      const SizedBox(height: 16),
                      _buildRiskDisclosure(),
                    ],
                    const SizedBox(height: 24),
                    _buildSubscriptionButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.backgroundPrimary,
      foregroundColor: AppColors.textPrimary,
      floating: true,
      snap: true,
      title: Text(
        detail.companyName,
        style: AppTextStyles.cardTitle,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandEmerald,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              detail.companyName.isNotEmpty
                  ? detail.companyName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.sectionHeading,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.title, style: AppTextStyles.sectionHeading),
              const SizedBox(height: 4),
              StatusBadge.fromString(detail.status),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferingTerms() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Offering terms', style: AppTextStyles.labelSmall),
          const SizedBox(height: 12),
          _TermRow(
            label: 'Price per share',
            value: Formatters.money(
              detail.pricePerShare,
              symbol: detail.currency,
            ),
          ),
          if (detail.totalShares != null) ...[
            const SizedBox(height: 8),
            _TermRow(
              label: 'Total shares',
              value: Formatters.compact(detail.totalShares!),
            ),
          ],
          if (detail.availableShares != null) ...[
            const SizedBox(height: 8),
            _TermRow(
              label: 'Available shares',
              value: Formatters.compact(detail.availableShares!),
            ),
          ],
          if (detail.minInvestment != null) ...[
            const SizedBox(height: 8),
            _TermRow(
              label: 'Minimum investment',
              value: Formatters.money(
                detail.minInvestment!,
                symbol: detail.currency,
              ),
            ),
          ],
          if (detail.maxInvestment != null) ...[
            const SizedBox(height: 8),
            _TermRow(
              label: 'Maximum investment',
              value: Formatters.money(
                detail.maxInvestment!,
                symbol: detail.currency,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDates() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscription period', style: AppTextStyles.labelSmall),
          const SizedBox(height: 12),
          if (detail.subscriptionStartDate != null)
            _TermRow(
              label: 'Opens',
              value: Formatters.dateMedium(detail.subscriptionStartDate!),
            ),
          if (detail.subscriptionStartDate != null &&
              detail.subscriptionEndDate != null)
            const SizedBox(height: 8),
          if (detail.subscriptionEndDate != null)
            _TermRow(
              label: 'Closes',
              value: Formatters.dateMedium(detail.subscriptionEndDate!),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 10),
        Text(body, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _buildRiskDisclosure() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail.riskDisclosure!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionButton(BuildContext context) {
    // Subscription execution is out of scope for Phase 1.
    // The button is shown as a planned feature but does not submit
    // a real subscription. It explains its status clearly.
    final isOpen = detail.isOpen;
    return Column(
      children: [
        DirshaButton(
          label: isOpen
              ? 'Subscribe (Coming in Phase 2)'
              : 'Subscriptions closed',
          onPressed: null, // Disabled — subscription is not implemented
          isEnabled: false,
        ),
        const SizedBox(height: 8),
        Text(
          isOpen
              ? 'Subscription functionality will be available in Phase 2.'
              : 'This offering is not currently accepting subscriptions.',
          style: AppTextStyles.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.financialSmall),
      ],
    );
  }
}

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IPO Details')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SkeletonCard(height: 80),
                const SizedBox(height: 12),
                const SkeletonCard(height: 160),
                const SizedBox(height: 12),
                const SkeletonCard(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
