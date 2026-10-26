import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Variant of the Dirsha button.
enum DirshaBtnVariant { primary, secondary, ghost, danger }

/// Standardized button used across all Dirsha screens.
///
/// Handles its own loading state so callers do not need to disable and
/// rebuild the button themselves. While [isLoading] is true, the button
/// shows a spinner and ignores taps.
class DirshaButton extends StatelessWidget {
  const DirshaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DirshaBtnVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.minWidth = double.infinity,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final DirshaBtnVariant variant;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double minWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading;

    return SizedBox(
      width: minWidth == double.infinity ? double.infinity : minWidth,
      height: height,
      child: switch (variant) {
        DirshaBtnVariant.primary => _buildElevated(context, canTap),
        DirshaBtnVariant.secondary => _buildOutlined(context, canTap),
        DirshaBtnVariant.ghost => _buildText(context, canTap),
        DirshaBtnVariant.danger => _buildDanger(context, canTap),
      },
    );
  }

  Widget _buildElevated(BuildContext context, bool canTap) {
    return ElevatedButton(
      onPressed: canTap ? onPressed : null,
      child: _child(Colors.white),
    );
  }

  Widget _buildOutlined(BuildContext context, bool canTap) {
    return OutlinedButton(
      onPressed: canTap ? onPressed : null,
      child: _child(AppColors.secondaryEmerald),
    );
  }

  Widget _buildText(BuildContext context, bool canTap) {
    return TextButton(
      onPressed: canTap ? onPressed : null,
      child: _child(AppColors.secondaryEmerald),
    );
  }

  Widget _buildDanger(BuildContext context, bool canTap) {
    final errColor = AppColors.errorOf(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.errorSurfaceOf(context),
        foregroundColor: errColor,
        side: BorderSide(color: errColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(minWidth, height),
        elevation: 0,
      ),
      onPressed: canTap ? onPressed : null,
      child: _child(errColor),
    );
  }

  Widget _child(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.buttonLabel.copyWith(color: textColor)),
        ],
      );
    }

    return Text(label, style: AppTextStyles.buttonLabel.copyWith(color: textColor));
  }
}
