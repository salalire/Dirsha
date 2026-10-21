import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/ipo_models.dart';
import '../providers/ipo_provider.dart';

/// IPO discovery screen — shows all available offerings.
class IpoListScreen extends StatefulWidget {
  const IpoListScreen({super.key});

  @override
  State<IpoListScreen> createState() => _IpoListScreenState();
}

class _IpoListScreenState extends State<IpoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IpoListProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('IPO Offerings')),
      body: Column(
        children: [
          if (AppConfig.useMockRepositories && !AppConfig.isProduction)
            const MockDataBanner(detail: 'Mock IPOs — not real offerings'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<IpoListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.hasLoaded) {
          return _buildSkeletons();
        }
        if (provider.error != null && !provider.hasLoaded) {
          return ErrorState(error: provider.error!, onRetry: provider.refresh);
        }
        if (provider.isEmpty) {
          return const EmptyState(
            title: 'No offerings available',
            message:
                'There are no IPOs available at this time. Check back later.',
            icon: Icons.business_center_outlined,
          );
        }
        return RefreshIndicator(
          color: AppColors.secondaryEmerald,
          backgroundColor: AppColors.cardSurface,
          onRefresh: provider.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.ipos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _IpoCard(
                ipo: provider.ipos[index],
                onTap: () => context.push('/ipos/${provider.ipos[index].id}'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletons() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const SkeletonCard(height: 130),
    );
  }
}

class _IpoCard extends StatelessWidget {
  const _IpoCard({required this.ipo, required this.onTap});

  final IpoSummary ipo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Company avatar placeholder
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
                      style: AppTextStyles.cardTitle.copyWith(
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
                        style: AppTextStyles.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ipo.title,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StatusBadge.fromString(ipo.status),
              ],
            ),
            if (ipo.shortDescription != null) ...[
              const SizedBox(height: 10),
              Text(
                ipo.shortDescription!,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  label: 'Price',
                  value: Formatters.money(
                    ipo.pricePerShare,
                    symbol: ipo.currency,
                  ),
                ),
                const SizedBox(width: 12),
                if (ipo.subscriptionEndDate != null)
                  _InfoChip(
                    label: 'Closes',
                    value: Formatters.dateShort(ipo.subscriptionEndDate!),
                  ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.financialSmall),
      ],
    );
  }
}
