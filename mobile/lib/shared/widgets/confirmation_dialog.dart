import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'dirsha_button.dart';

/// A standardized confirmation dialog for destructive or important actions.
///
/// Returns true if the user confirms, false or null if they cancel.
///
/// Usage:
/// ```dart
/// final confirmed = await ConfirmationDialog.show(
///   context,
///   title: 'Sign out',
///   message: 'Are you sure you want to sign out?',
///   confirmLabel: 'Sign out',
///   isDangerous: true,
/// );
/// if (confirmed == true) { ... }
/// ```
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDangerous = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: AppTextStyles.sectionHeadingOf(context)),
      content: Text(message, style: AppTextStyles.bodyMediumOf(context)),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        SizedBox(
          height: 44,
          child: DirshaButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
            variant: DirshaBtnVariant.ghost,
            minWidth: 100,
            height: 44,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: DirshaButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
            variant: isDangerous
                ? DirshaBtnVariant.danger
                : DirshaBtnVariant.primary,
            minWidth: 120,
            height: 44,
          ),
        ),
      ],
    );
  }
}
