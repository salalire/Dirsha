import 'package:flutter/material.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'dirsha_button.dart';

/// Shown when a screen or section fails to load.
///
/// Always distinguishes a network failure from a server error from an
/// empty result. Provides a retry action when the operation can be retried.
///
/// Security: never display raw exception messages or stack traces to the
/// user. The [error] is used only to select the appropriate user-facing
/// message.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final Object error;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = _messageFor(error);

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
                color: AppColors.errorSurfaceOf(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.errorOf(context).withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, size: 32, color: AppColors.errorOf(context)),
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
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              DirshaButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: DirshaBtnVariant.secondary,
                minWidth: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _messageFor(Object error) {
    if (error is NetworkException || error is TimeoutException) {
      return (
        Icons.wifi_off_rounded,
        'No connection',
        'Check your internet connection and try again.',
      );
    }
    if (error is UnauthorizedException) {
      return (
        Icons.lock_outline_rounded,
        'Session expired',
        'Please sign in again to continue.',
      );
    }
    if (error is ForbiddenException) {
      return (
        Icons.block_rounded,
        'Access denied',
        'You do not have permission to view this.',
      );
    }
    if (error is NotFoundException) {
      return (
        Icons.search_off_rounded,
        'Not found',
        'The requested item is no longer available.',
      );
    }
    // Generic server / parse error — do not expose internal detail.
    return (
      Icons.error_outline_rounded,
      'Something went wrong',
      'We could not load this content. Please try again.',
    );
  }
}
