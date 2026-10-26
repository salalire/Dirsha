import 'package:flutter/material.dart';

/// Official Dirsha Dark Emerald Fintech color palette.
///
/// All color values are centralized here. Do not scatter hex literals
/// across individual screen or widget files.
///
/// Coordinate any meaningful changes with Member 3 (admin dashboard) and
/// the project owner to keep the shared Dirsha brand identity consistent.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand greens
  // ---------------------------------------------------------------------------

  /// Primary brand emerald — used for primary actions, key highlights.
  static const Color brandEmerald = Color(0xFF064E3B);

  /// Secondary emerald — hover/active states, secondary accents.
  static const Color secondaryEmerald = Color(0xFF047857);

  /// Deep forest green — background gradients, subtle overlays.
  static const Color deepForest = Color(0xFF022C22);

  // ---------------------------------------------------------------------------
  // Dark backgrounds
  // ---------------------------------------------------------------------------

  /// Primary background — the base screen surface.
  static const Color backgroundPrimary = Color(0xFF080B09);

  /// Secondary background — slightly elevated sections.
  static const Color backgroundSecondary = Color(0xFF101612);

  /// Card surface — default card / tile background.
  static const Color cardSurface = Color(0xFF141A16);

  /// Elevated card surface — cards that sit above the base surface.
  static const Color cardElevated = Color(0xFF1B241D);

  // ---------------------------------------------------------------------------
  // Gold accent
  // ---------------------------------------------------------------------------

  /// Ethiopian gold — use sparingly as an accent, never as the dominant color.
  static const Color gold = Color(0xFFD4A72C);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Primary text on dark surfaces.
  static const Color textPrimary = Color(0xFFF5F7F5);

  /// Secondary / supporting text on dark surfaces.
  static const Color textSecondary = Color(0xFFA7B3AA);

  /// Disabled text — visually distinct but not active.
  static const Color textDisabled = Color(0xFF5A6B5E);

  // ---------------------------------------------------------------------------
  // Borders and dividers
  // ---------------------------------------------------------------------------

  /// Subtle border — card outlines, dividers, input borders.
  static const Color border = Color(0xFF2A352D);

  /// Focused input border — brighter than the resting border.
  static const Color borderFocused = Color(0xFF047857);

  // ---------------------------------------------------------------------------
  // Semantic status colors
  // ---------------------------------------------------------------------------

  /// Success — confirmed operations, open IPOs, available balance.
  static const Color success = Color(0xFF22C55E);

  /// Error — failed operations, validation errors, closed/rejected.
  static const Color error = Color(0xFFF87171);

  /// Warning — pending operations, upcoming deadlines, reserved funds.
  static const Color warning = Color(0xFFFBBF24);

  /// Information — neutral status messages, informational badges.
  static const Color info = Color(0xFF60A5FA);

  // ---------------------------------------------------------------------------
  // Semantic surface tints (for status backgrounds)
  // ---------------------------------------------------------------------------

  static const Color successSurface = Color(0xFF052E16);
  static const Color errorSurface = Color(0xFF2D0A0A);
  static const Color warningSurface = Color(0xFF2D1F00);
  static const Color infoSurface = Color(0xFF0A1929);

  // ---------------------------------------------------------------------------
  // Light mode surfaces and text
  // ---------------------------------------------------------------------------

  /// Light primary background — base screen surface in light mode.
  static const Color lightBackgroundPrimary = Color(0xFFF5F7F5);

  /// Light secondary background — elevated sections in light mode.
  static const Color lightBackgroundSecondary = Color(0xFFFFFFFF);

  /// Light card surface — default card / tile background in light mode.
  static const Color lightCardSurface = Color(0xFFFFFFFF);

  /// Light elevated card surface — slightly tinted elevated card in light mode.
  static const Color lightCardElevated = Color(0xFFF0F4F1);

  /// Light borders and dividers.
  static const Color lightBorder = Color(0xFFDDE4DF);

  /// Primary text on light surfaces.
  static const Color lightTextPrimary = Color(0xFF0D1A12);

  /// Secondary text on light surfaces.
  static const Color lightTextSecondary = Color(0xFF4A5E50);

  /// Disabled text on light surfaces.
  static const Color lightTextDisabled = Color(0xFF9AB0A0);

  // ---------------------------------------------------------------------------
  // Light semantic status colors & surface tints
  // ---------------------------------------------------------------------------

  static const Color lightSuccess = Color(0xFF15803D);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightWarning = Color(0xFFB45309);
  static const Color lightInfo = Color(0xFF2563EB);

  static const Color lightSuccessSurface = Color(0xFFDCFCE7);
  static const Color lightErrorSurface = Color(0xFFFEE2E2);
  static const Color lightWarningSurface = Color(0xFFFEF3CC);
  static const Color lightInfoSurface = Color(0xFFE0F2FE);

  // ---------------------------------------------------------------------------
  // Overlay / scrim
  // ---------------------------------------------------------------------------

  /// Modal / dialog scrim.
  static const Color scrim = Color(0xCC000000);

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Transparent — use instead of Colors.transparent for consistency.
  static const Color transparent = Color(0x00000000);

  // ---------------------------------------------------------------------------
  // Theme-aware helpers
  // ---------------------------------------------------------------------------

  /// Whether the active theme is dark mode.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Theme-aware primary background color.
  static Color backgroundPrimaryOf(BuildContext context) =>
      isDark(context) ? backgroundPrimary : lightBackgroundPrimary;

  /// Theme-aware secondary background color.
  static Color backgroundSecondaryOf(BuildContext context) =>
      isDark(context) ? backgroundSecondary : lightBackgroundSecondary;

  /// Theme-aware card surface color.
  static Color cardSurfaceOf(BuildContext context) =>
      isDark(context) ? cardSurface : lightCardSurface;

  /// Theme-aware elevated card color.
  static Color cardElevatedOf(BuildContext context) =>
      isDark(context) ? cardElevated : lightCardElevated;

  /// Theme-aware border color.
  static Color borderOf(BuildContext context) =>
      isDark(context) ? border : lightBorder;

  /// Theme-aware primary text color.
  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  /// Theme-aware secondary text color.
  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  /// Theme-aware disabled text color.
  static Color textDisabledOf(BuildContext context) =>
      isDark(context) ? textDisabled : lightTextDisabled;

  /// Theme-aware success status color.
  static Color successOf(BuildContext context) =>
      isDark(context) ? success : lightSuccess;

  /// Theme-aware error status color.
  static Color errorOf(BuildContext context) =>
      isDark(context) ? error : lightError;

  /// Theme-aware warning status color.
  static Color warningOf(BuildContext context) =>
      isDark(context) ? warning : lightWarning;

  /// Theme-aware info status color.
  static Color infoOf(BuildContext context) =>
      isDark(context) ? info : lightInfo;

  /// Theme-aware success surface tint.
  static Color successSurfaceOf(BuildContext context) =>
      isDark(context) ? successSurface : lightSuccessSurface;

  /// Theme-aware error surface tint.
  static Color errorSurfaceOf(BuildContext context) =>
      isDark(context) ? errorSurface : lightErrorSurface;

  /// Theme-aware warning surface tint.
  static Color warningSurfaceOf(BuildContext context) =>
      isDark(context) ? warningSurface : lightWarningSurface;

  /// Theme-aware info surface tint.
  static Color infoSurfaceOf(BuildContext context) =>
      isDark(context) ? infoSurface : lightInfoSurface;
}
