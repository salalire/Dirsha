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
  // Overlay / scrim
  // ---------------------------------------------------------------------------

  /// Modal / dialog scrim.
  static const Color scrim = Color(0xCC000000);

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Transparent — use instead of Colors.transparent for consistency.
  static const Color transparent = Color(0x00000000);
}
