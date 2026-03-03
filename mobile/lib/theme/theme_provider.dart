import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    initialized = _loadThemePreference();
  }

  ThemeOption _themeOption = ThemeOption.system;
  SharedPreferences? _prefs;

  late final Future<void> initialized;

  static const String _themeKey = 'theme_option';

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
    if (_themeOption == option) {
      return;
    }

    _themeOption = option;
    notifyListeners();
    await _saveThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await _getPrefs();
    final themeName = prefs.getString(_themeKey);
    if (themeName == null) {
      return;
    }

    final resolvedTheme = ThemeOption.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeOption.system,
    );

    if (_themeOption == resolvedTheme) {
      return;
    }

    _themeOption = resolvedTheme;
    notifyListeners();
  }

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _prefs;
    if (prefs != null) {
      return prefs;
    }
    final createdPrefs = await SharedPreferences.getInstance();
    _prefs = createdPrefs;
    return createdPrefs;
  }

  Future<void> _saveThemePreference() async {
    final prefs = await _getPrefs();
    await prefs.setString(_themeKey, _themeOption.name);
  }
}
