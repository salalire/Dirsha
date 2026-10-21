import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Dirsha theme definitions.
///
/// [AppTheme.dark]  — Dark Emerald Fintech (default, Phase 1 primary).
/// [AppTheme.light] — Light Emerald Fintech (follows device system setting).
///
/// Both themes share the same Dirsha brand identity:
///   - Emerald primary actions and accents.
///   - Ethiopian gold as a secondary accent.
///   - Consistent semantic status colors (success/error/warning/info).
///   - Inter typeface throughout.
///
/// The app defaults to [ThemeMode.system] so dark mode users see the dark
/// theme and light mode users see the light theme. Dark mode is the designed
/// and tested primary experience.
abstract final class AppTheme {
  // ---------------------------------------------------------------------------
  // DARK THEME — primary experience
  // ---------------------------------------------------------------------------

  /// Dark Emerald Fintech theme. The default Dirsha mobile experience.
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
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
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
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
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondaryEmerald,
        linearTrackColor: AppColors.border,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
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
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
    );
  }

  // ---------------------------------------------------------------------------
  // LIGHT THEME
  // ---------------------------------------------------------------------------

  /// Light Emerald Fintech theme. Activated when the device is in light mode.
  ///
  /// Same Dirsha brand identity as the dark theme:
  ///   - Emerald primary actions.
  ///   - Ethiopian gold accent.
  ///   - White/light-gray surfaces with dark readable text.
  ///   - Consistent semantic status colors.
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    // Light-mode surface values
    const bgPrimary = Color(0xFFF5F7F5); // Very light gray-green tint
    const bgSecondary = Color(0xFFFFFFFF); // Pure white
    const cardSurface = Color(0xFFFFFFFF); // White cards
    const cardElevated = Color(0xFFF0F4F1); // Slightly tinted elevated card
    const borderLight = Color(0xFFDDE4DF); // Soft green-gray border
    const textPrimary = Color(0xFF0D1A12); // Near-black with green tint
    const textSecondary = Color(0xFF4A5E50); // Muted dark green-gray
    const textDisabled = Color(0xFF9AB0A0); // Light disabled

    return base.copyWith(
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.secondaryEmerald,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD0EDE4),
        onPrimaryContainer: AppColors.brandEmerald,
        secondary: AppColors.gold,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFF3CC),
        onSecondaryContainer: Color(0xFF5C3E00),
        tertiary: AppColors.info,
        onTertiary: Colors.white,
        surface: bgSecondary,
        onSurface: textPrimary,
        surfaceContainerHighest: cardElevated,
        onSurfaceVariant: textSecondary,
        outline: borderLight,
        outlineVariant: borderLight,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFE4E4),
        onErrorContainer: Color(0xFF7A1010),
        scrim: AppColors.scrim,
        shadow: Color(0x1A000000),
      ),
      // -----------------------------------------------------------------
      // AppBar — light surfaces, dark icons, dark status bar icons
      // -----------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: bgSecondary,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: borderLight,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // dark icons on light bg
          statusBarBrightness: Brightness.light,
        ),
      ),
      // -----------------------------------------------------------------
      // Cards
      // -----------------------------------------------------------------
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
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
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderLight,
          disabledForegroundColor: textDisabled,
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
          disabledForegroundColor: textDisabled,
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
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondaryEmerald,
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
        hintStyle: GoogleFonts.inter(fontSize: 15, color: textDisabled),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.secondaryEmerald,
        ),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      // -----------------------------------------------------------------
      // Bottom / Navigation bar
      // -----------------------------------------------------------------
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSecondary,
        selectedItemColor: AppColors.secondaryEmerald,
        unselectedItemColor: textSecondary,
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgSecondary,
        indicatorColor: Color(0xFFD0EDE4), // light emerald tint
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.secondaryEmerald);
          }
          return const IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryEmerald,
            );
          }
          return GoogleFonts.inter(fontSize: 12, color: textSecondary);
        }),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      // -----------------------------------------------------------------
      // Dividers
      // -----------------------------------------------------------------
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      // -----------------------------------------------------------------
      // Dialog
      // -----------------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight),
        ),
        elevation: 2,
        shadowColor: const Color(0x1A000000),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
      ),
      // -----------------------------------------------------------------
      // Snackbar
      // -----------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: bgSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      // -----------------------------------------------------------------
      // Chip
      // -----------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: cardElevated,
        selectedColor: const Color(0xFFD0EDE4),
        disabledColor: borderLight,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: textPrimary),
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      // -----------------------------------------------------------------
      // Progress indicator
      // -----------------------------------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondaryEmerald,
        linearTrackColor: borderLight,
      ),
      // -----------------------------------------------------------------
      // Text theme
      // -----------------------------------------------------------------
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      // -----------------------------------------------------------------
      // List tile
      // -----------------------------------------------------------------
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.transparent,
        iconColor: textSecondary,
        textColor: textPrimary,
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      // -----------------------------------------------------------------
      // Icon
      // -----------------------------------------------------------------
      iconTheme: const IconThemeData(color: textSecondary, size: 24),
    );
  }
}
