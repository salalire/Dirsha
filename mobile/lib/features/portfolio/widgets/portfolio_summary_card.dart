import 'package:flutter/material.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../models/portfolio_models.dart';

class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({
    super.key,
    required this.summary,
  });

  final PortfolioSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardSurface,
            AppColors.deepForest,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondaryEmerald.withAlpha(80),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandEmerald.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PORTFOLIO VALUATION',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withAlpha(80),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Simulated Funds',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            Formatters.money(Money(summary.totalValuationMinor)),
            style: AppTextStyles.balanceHero.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Valuation source: Offering Price (FR-PORT-03)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withAlpha(180),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardElevated, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Total Positions',
                  value: '${summary.totalPositions}',
                  icon: Icons.layers_outlined,
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: AppColors.cardElevated,
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Total Shares',
                  value: '${summary.totalShares}',
                  icon: Icons.bar_chart_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
