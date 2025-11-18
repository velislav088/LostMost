import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption {
  system,
  light,
  dark,
}

class ThemeProvider extends ChangeNotifier {
  ThemeOption _themeOption = ThemeOption.system;
  static const String _themeKey = 'theme_option';

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeOption get themeOption => _themeOption;

  ThemeMode get themeMode {
    switch (_themeOption) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeOption(ThemeOption option) async {
    _themeOption = option;
    notifyListeners();
    await _saveThemePreference();
  }

    // Loads saved theme from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    if (themeName != null) {
      _themeOption = ThemeOption.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => ThemeOption.system,
      );
      notifyListeners();
    }
  }

  // Save current theme
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeOption.name);
  }
}