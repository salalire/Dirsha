import 'package:flutter/material.dart';

/// Ethiopian Emerald Design System — Dirsha Admin Dashboard
/// All color constants live here. Never scatter hex values across screens.
abstract final class AppColors {
  // ── Brand (same in both modes) ─────────────────────────────────────────────
  static const Color primary = Color(0xFF064E3B);
  static const Color primaryLight = Color(0xFF047857);
  static const Color accent = Color(0xFFD4A72C);

  // ── Semantic (same in both modes) ──────────────────────────────────────────
  static const Color success = Color(0xFF15803D);
  static const Color error = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFB45309);
  static const Color info = Color(0xFF1D4ED8);

  // ── Light mode ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF17231F);
  static const Color textSecondary = Color(0xFF64756C);
  static const Color border = Color(0xFFDCE5DD);

  // ── Dark mode ──────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1410);
  static const Color darkSurface = Color(0xFF1A2420);
  static const Color darkSurfaceVariant = Color(0xFF243028);
  static const Color darkTextPrimary = Color(0xFFE8F0EC);
  static const Color darkTextSecondary = Color(0xFF8BA898);
  static const Color darkBorder = Color(0xFF2D3F38);

  // ── Sidebar (same in both modes — sidebar is always dark) ──────────────────
  static const Color sidebarBackground = Color(0xFF043D2E);
  static const Color sidebarActive = Color(0xFF047857);
  static const Color sidebarText = Color(0xFFBBD5CA);
  static const Color sidebarActiveText = Color(0xFFFFFFFF);

  // ── Dark semantic badges ───────────────────────────────────────────────────
  static const Color darkSuccessBg = Color(0xFF14532D);
  static const Color darkErrorBg = Color(0xFF7F1D1D);
  static const Color darkWarningBg = Color(0xFF78350F);
  static const Color darkInfoBg = Color(0xFF1E3A5F);
}
