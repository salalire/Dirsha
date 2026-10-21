import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the current theme mode and persists the user's preference.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _load();
  }

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == 'light') {
      _mode = ThemeMode.light;
      notifyListeners();
    }
    // If saved == 'dark' or no preference saved, dark remains the default.
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
  }
}
