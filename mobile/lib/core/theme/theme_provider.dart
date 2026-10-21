import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-level theme mode (dark / light).
///
/// The user's preference is persisted via [SharedPreferences] so the
/// chosen mode survives app restarts.
///
/// Default: [ThemeMode.dark] — the Dirsha Dark Emerald Fintech experience.
///
/// Usage:
/// ```dart
/// // Read current mode
/// context.watch<ThemeProvider>().themeMode
///
/// // Toggle
/// context.read<ThemeProvider>().toggleTheme()
/// ```
class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();

  static const _key = 'dirsha_theme_mode';

  ThemeMode _themeMode = ThemeMode.dark; // dark is the default

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Factory — loads the persisted preference before the first frame.
  /// Always call this and await it before using the provider.
  static Future<ThemeProvider> create() async {
    final provider = ThemeProvider._();
    await provider._load();
    return provider;
  }

  /// Toggles between dark and light and persists the choice.
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    await _save();
  }

  /// Sets the theme mode explicitly.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _save();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark; // default when nothing is stored
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
