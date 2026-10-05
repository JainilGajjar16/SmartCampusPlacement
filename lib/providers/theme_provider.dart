import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Provider managing Light Mode and Dark Mode state with SharedPreferences persistence.
class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'user_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'system') {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.dark) {
        await prefs.setString(_themePrefKey, 'dark');
      } else if (mode == ThemeMode.light) {
        await prefs.setString(_themePrefKey, 'light');
      } else {
        await prefs.setString(_themePrefKey, 'system');
      }
    } catch (_) {}
  }

  Future<void> toggleTheme(BuildContext context) async {
    final dark = isDarkMode(context);
    await setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
  }
}
