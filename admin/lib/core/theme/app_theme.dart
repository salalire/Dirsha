import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  // ── Shared sub-builders ───────────────────────────────────────────────────

  static ButtonStyle _elevatedBtn(Color bg, Color fg) =>
      ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );

  static ButtonStyle _outlinedBtn(Color fg, Color side) =>
      OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: side),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );

  static InputDecorationTheme _inputTheme(
          Color fill, Color border, Color label) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: label),
        hintStyle: TextStyle(color: label),
        errorStyle:
            const TextStyle(color: AppColors.error, fontSize: 12),
      );

  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: Color(0xFFFDF3D0),
      onSecondaryContainer: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: _elevatedBtn(AppColors.primary, Colors.white)),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: _outlinedBtn(AppColors.primary, AppColors.primary)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: _inputTheme(
          AppColors.surface, AppColors.border, AppColors.textSecondary),
      dividerTheme: const DividerThemeData(
          color: AppColors.border, thickness: 1, space: 0),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        labelStyle: const TextStyle(
            fontSize: 12, color: AppColors.textPrimary),
      ),
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.darkTextPrimary,
      secondaryContainer: Color(0xFF3D2E00),
      onSecondaryContainer: AppColors.darkTextPrimary,
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkBackground,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: _elevatedBtn(AppColors.primaryLight, Colors.white)),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: _outlinedBtn(
              AppColors.primaryLight, AppColors.primaryLight)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: _inputTheme(AppColors.darkSurfaceVariant,
          AppColors.darkBorder, AppColors.darkTextSecondary),
      dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder, thickness: 1, space: 0),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        labelStyle: const TextStyle(
            fontSize: 12, color: AppColors.darkTextPrimary),
      ),
      textTheme:
          _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurfaceVariant,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Shared text theme ─────────────────────────────────────────────────────
  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        headlineLarge: TextStyle(
            fontSize: 30, fontWeight: FontWeight.w700, color: primary),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: primary),
        headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: primary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: primary),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
        labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: secondary,
            letterSpacing: 0.5),
      );
}
