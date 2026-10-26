import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Dirsha typography hierarchy.
///
/// Uses Inter (via google_fonts) — clean, modern, highly legible on dark
/// surfaces. All weights and sizes are defined here; do not set font sizes
/// directly in widgets.
///
/// Financial figures (balances, amounts, prices) use tabular figures
/// (fontFeatures: [FontFeature.tabularFigures()]) for aligned columns.
abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // Internal helper — base style with Inter
  // ---------------------------------------------------------------------------

  static TextStyle _base({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: fontFeatures,
    );
  }

  // ---------------------------------------------------------------------------
  // Screen and section titles
  // ---------------------------------------------------------------------------

  /// Large screen title — e.g. "Investor Dashboard"
  static TextStyle get screenTitle =>
      _base(size: 24, weight: FontWeight.w700, letterSpacing: -0.3);

  /// Section heading — e.g. "IPO Opportunities", "Recent Transactions"
  static TextStyle get sectionHeading =>
      _base(size: 18, weight: FontWeight.w600, letterSpacing: -0.2);

  /// Card / tile title — e.g. company name in an IPO card
  static TextStyle get cardTitle => _base(size: 16, weight: FontWeight.w600);

  // ---------------------------------------------------------------------------
  // Body text
  // ---------------------------------------------------------------------------

  /// Primary body — standard readable content
  static TextStyle get bodyLarge => _base(size: 16, height: 1.5);

  /// Secondary body — descriptions, supporting info
  static TextStyle get bodyMedium =>
      _base(size: 14, height: 1.5, color: AppColors.textSecondary);

  /// Small body — compact supporting text
  static TextStyle get bodySmall =>
      _base(size: 13, height: 1.4, color: AppColors.textSecondary);

  // ---------------------------------------------------------------------------
  // Financial figures — uses tabular figures for clean alignment
  // ---------------------------------------------------------------------------

  /// Hero balance — large, prominent wallet balance display
  static TextStyle get balanceHero => _base(
    size: 32,
    weight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Large financial figure — IPO price, subscription amounts
  static TextStyle get financialLarge => _base(
    size: 22,
    weight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Medium financial figure — card summaries, transaction amounts
  static TextStyle get financialMedium => _base(
    size: 16,
    weight: FontWeight.w600,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Small financial figure — transaction rows, secondary amounts
  static TextStyle get financialSmall => _base(
    size: 14,
    weight: FontWeight.w500,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // ---------------------------------------------------------------------------
  // Labels and badges
  // ---------------------------------------------------------------------------

  /// Status badge label — e.g. "OPEN", "CLOSED", "PENDING"
  static TextStyle get badgeLabel =>
      _base(size: 11, weight: FontWeight.w700, letterSpacing: 0.6);

  /// Small label — form field labels, metadata keys
  static TextStyle get labelSmall => _base(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------

  /// Primary / secondary button label — color is null so it inherits
  /// from the active button theme (ElevatedButton, OutlinedButton, TextButton).
  static TextStyle get buttonLabel =>
      _base(size: 15, weight: FontWeight.w600, letterSpacing: 0.1, color: null);

  // ---------------------------------------------------------------------------
  // Form inputs
  // ---------------------------------------------------------------------------

  /// Input field text
  static TextStyle get inputText => _base(size: 15);

  /// Input hint / placeholder
  static TextStyle get inputHint =>
      _base(size: 15, color: AppColors.textDisabled);

  // ---------------------------------------------------------------------------
  // Authentication screens
  // ---------------------------------------------------------------------------

  /// App name / headline on auth screens
  static TextStyle get authHeadline =>
      _base(size: 28, weight: FontWeight.w700, letterSpacing: -0.5);

  /// Auth subtitle / instruction
  static TextStyle get authSubtitle =>
      _base(size: 15, color: AppColors.textSecondary, height: 1.5);

  // ---------------------------------------------------------------------------
  // Empty / error states
  // ---------------------------------------------------------------------------

  static TextStyle get emptyStateTitle =>
      _base(size: 17, weight: FontWeight.w600);

  static TextStyle get emptyStateBody =>
      _base(size: 14, color: AppColors.textSecondary, height: 1.5);

  // ---------------------------------------------------------------------------
  // Theme-aware styles (dynamically adjust to Light and Dark modes)
  // ---------------------------------------------------------------------------

  static TextStyle screenTitleOf(BuildContext context) =>
      screenTitle.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle sectionHeadingOf(BuildContext context) =>
      sectionHeading.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle cardTitleOf(BuildContext context) =>
      cardTitle.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle bodyLargeOf(BuildContext context) =>
      bodyLarge.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle bodyMediumOf(BuildContext context) =>
      bodyMedium.copyWith(color: AppColors.textSecondaryOf(context));

  static TextStyle bodySmallOf(BuildContext context) =>
      bodySmall.copyWith(color: AppColors.textSecondaryOf(context));

  static TextStyle balanceHeroOf(BuildContext context) =>
      balanceHero.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle financialLargeOf(BuildContext context) =>
      financialLarge.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle financialMediumOf(BuildContext context) =>
      financialMedium.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle financialSmallOf(BuildContext context) =>
      financialSmall.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle badgeLabelOf(BuildContext context, [Color? color]) =>
      badgeLabel.copyWith(color: color ?? AppColors.textPrimaryOf(context));

  static TextStyle labelSmallOf(BuildContext context) =>
      labelSmall.copyWith(color: AppColors.textSecondaryOf(context));

  static TextStyle buttonLabelOf(BuildContext context, [Color? color]) =>
      buttonLabel.copyWith(color: color);

  static TextStyle inputTextOf(BuildContext context) =>
      inputText.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle inputHintOf(BuildContext context) =>
      inputHint.copyWith(color: AppColors.textDisabledOf(context));

  static TextStyle authHeadlineOf(BuildContext context) =>
      authHeadline.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle authSubtitleOf(BuildContext context) =>
      authSubtitle.copyWith(color: AppColors.textSecondaryOf(context));

  static TextStyle emptyStateTitleOf(BuildContext context) =>
      emptyStateTitle.copyWith(color: AppColors.textPrimaryOf(context));

  static TextStyle emptyStateBodyOf(BuildContext context) =>
      emptyStateBody.copyWith(color: AppColors.textSecondaryOf(context));
}
