import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'dirsha_button.dart';

/// Shown when a list or screen has no data to display.
///
/// Always explain why the list is empty rather than showing a blank screen.
/// Never treat an empty result as an error.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceOf(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Icon(icon, size: 32, color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.emptyStateTitleOf(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.emptyStateBodyOf(context),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              DirshaButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: DirshaBtnVariant.secondary,
                minWidth: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
