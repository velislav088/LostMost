import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {

  SettingsProvider() {
    _loadSettings();
  }
  static const String _localeKey = 'locale';
  static const String _dataSaverKey = 'data_saver';

  Locale _locale = const Locale('en');
  bool _dataSaverEnabled = false;

  Locale get locale => _locale;
  bool get dataSaverEnabled => _dataSaverEnabled;

  // get user preference
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(localeCode);
    _dataSaverEnabled = prefs.getBool(_dataSaverKey) ?? false;
    notifyListeners();
  }

  // Save user preference locally
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  /// Sets data saver preference
  Future<void> setDataSaver(bool enabled) async {
    if (_dataSaverEnabled == enabled) {
      return;
    }
    _dataSaverEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataSaverKey, enabled);
    notifyListeners();
  }
}
