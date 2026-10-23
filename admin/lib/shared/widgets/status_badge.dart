import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A colored badge for displaying status values (Pending, Approved, etc.).
///
/// Color is conveyed both visually AND via the label text to meet
/// accessibility requirements (not color-only communication).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  final String label;
  final Color color;
  final Color? textColor;

  // ── Named constructors for each status type ───────────────────────────────

  factory StatusBadge.pending() => const StatusBadge(
        label: 'Pending',
        color: Color(0xFFFEF3C7),
        textColor: Color(0xFF92400E),
      );

  factory StatusBadge.underReview() => const StatusBadge(
        label: 'Under Review',
        color: Color(0xFFDEEBFF),
        textColor: AppColors.info,
      );

  factory StatusBadge.additionalInfoRequired() => const StatusBadge(
        label: 'Info Required',
        color: Color(0xFFFEF3C7),
        textColor: Color(0xFFB45309),
      );

  factory StatusBadge.approved() => const StatusBadge(
        label: 'Approved',
        color: Color(0xFFDCFCE7),
        textColor: AppColors.success,
      );

  factory StatusBadge.rejected() => const StatusBadge(
        label: 'Rejected',
        color: Color(0xFFFEE2E2),
        textColor: AppColors.error,
      );

  factory StatusBadge.suspended() => const StatusBadge(
        label: 'Suspended',
        color: Color(0xFFF3F4F6),
        textColor: Color(0xFF374151),
      );

  factory StatusBadge.open() => const StatusBadge(
        label: 'Open',
        color: Color(0xFFD1FAE5),
        textColor: AppColors.success,
      );

  factory StatusBadge.closed() => const StatusBadge(
        label: 'Closed',
        color: Color(0xFFF3F4F6),
        textColor: Color(0xFF374151),
      );

  factory StatusBadge.fromLabel(String label) {
    switch (label.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
        return StatusBadge.pending();
      case 'under_review':
        return StatusBadge.underReview();
      case 'additional_info_required':
      case 'info_required':
        return StatusBadge.additionalInfoRequired();
      case 'approved':
        return StatusBadge.approved();
      case 'rejected':
        return StatusBadge.rejected();
      case 'suspended':
        return StatusBadge.suspended();
      case 'open':
        return StatusBadge.open();
      case 'closed':
      case 'withdrawn':
        return StatusBadge.closed();
      default:
        return StatusBadge(
          label: label,
          color: AppColors.border,
          textColor: AppColors.textSecondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
