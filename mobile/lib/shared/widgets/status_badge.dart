import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Visual variants that map to Dirsha's semantic status colors.
///
/// These align with the status values defined in the agreed API contract
/// (Member 2). Update [StatusBadge.fromString] when the contract is finalized.
enum BadgeVariant { success, error, warning, info, neutral }

/// A compact status label used on IPO cards, transaction rows, and
/// allocation results.
///
/// Do not use color alone as the sole indicator — the label text must always
/// convey the status meaning.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.variant});

  /// Creates a badge from an API status string.
  ///
  /// Maps the agreed status values from the API contract. Unknown strings
  /// fall back to [BadgeVariant.neutral] rather than crashing.
  factory StatusBadge.fromString(String status) {
    final variant = switch (status.toUpperCase()) {
      'OPEN' ||
      'ACTIVE' ||
      'COMPLETED' ||
      'ALLOCATED' ||
      'LISTED' => BadgeVariant.success,
      'CLOSED' ||
      'REJECTED' ||
      'FAILED' ||
      'CANCELLED' ||
      'EXPIRED' => BadgeVariant.error,
      'PENDING' ||
      'SUBMITTED' ||
      'UNDER_REVIEW' ||
      'RESERVED' => BadgeVariant.warning,
      'DRAFT' || 'UPCOMING' => BadgeVariant.info,
      _ => BadgeVariant.neutral,
    };
    return StatusBadge(label: status, variant: variant);
  }

  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BadgeVariant.success => (AppColors.successSurface, AppColors.success),
      BadgeVariant.error => (AppColors.errorSurface, AppColors.error),
      BadgeVariant.warning => (AppColors.warningSurface, AppColors.warning),
      BadgeVariant.info => (AppColors.infoSurface, AppColors.info),
      BadgeVariant.neutral => (AppColors.cardElevated, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.badgeLabel.copyWith(color: fg),
      ),
    );
  }
}
