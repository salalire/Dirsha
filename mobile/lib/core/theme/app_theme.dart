import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Dirsha Dark Emerald Fintech theme.
///
/// This is the default and only theme for Phase 1. All colors are sourced from
/// [AppColors]; no hex literals appear here. Light theme support is deferred
/// to a later phase.
abstract final class AppTheme {
  /// Returns the fully configured dark emerald [ThemeData].
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      // -----------------------------------------------------------------
      // Color scheme
      // -----------------------------------------------------------------
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.secondaryEmerald,
        onPrimary: AppColors.textPrimary,
        primaryContainer: AppColors.brandEmerald,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.gold,
        onSecondary: AppColors.backgroundPrimary,
        secondaryContainer: Color(0xFF2A1F00),
        onSecondaryContainer: AppColors.gold,
        tertiary: AppColors.info,
        onTertiary: AppColors.backgroundPrimary,
        surface: AppColors.backgroundSecondary,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.cardElevated,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        error: AppColors.error,
        onError: AppColors.backgroundPrimary,
        errorContainer: AppColors.errorSurface,
        onErrorContainer: AppColors.error,
        scrim: AppColors.scrim,
        shadow: Color(0xFF000000),
      ),
      // -----------------------------------------------------------------
      // System UI overlay — keep status bar icons light on dark surfaces
      // -----------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      // -----------------------------------------------------------------
      // Cards
      // -----------------------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      // -----------------------------------------------------------------
      // Buttons
      // -----------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryEmerald,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondaryEmerald,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.secondaryEmerald, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryEmerald,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // -----------------------------------------------------------------
      // Input fields
      // -----------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.borderFocused,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textDisabled,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.secondaryEmerald,
        ),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      // -----------------------------------------------------------------
      // Bottom navigation bar
      // -----------------------------------------------------------------
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedItemColor: AppColors.secondaryEmerald,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        indicatorColor: AppColors.brandEmerald,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.textPrimary);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          );
        }),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      // -----------------------------------------------------------------
      // Dividers
      // -----------------------------------------------------------------
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      // -----------------------------------------------------------------
      // Dialog
      // -----------------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      // -----------------------------------------------------------------
      // Snackbar
      // -----------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardElevated,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      // -----------------------------------------------------------------
      // Chip
      // -----------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardSurface,
        selectedColor: AppColors.brandEmerald,
        disabledColor: AppColors.border,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      // -----------------------------------------------------------------
      // Progress indicator
      // -----------------------------------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondaryEmerald,
        linearTrackColor: AppColors.border,
      ),
      // -----------------------------------------------------------------
      // Text theme — base provided by Google Fonts; individual styles
      // come from AppTextStyles rather than the text theme.
      // -----------------------------------------------------------------
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      // -----------------------------------------------------------------
      // List tile
      // -----------------------------------------------------------------
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.transparent,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      // -----------------------------------------------------------------
      // Icon
      // -----------------------------------------------------------------
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
    );
  }
}
