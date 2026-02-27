import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    initialized = _loadSettings();
  }

  late final Future<void> initialized;

  static const String _localeKey = 'locale';
  static const String _dataSaverKey = 'data_saver';

  Locale _locale = const Locale('en');
  bool _dataSaverEnabled = false;
  SharedPreferences? _prefs;

  Locale get locale => _locale;
  bool get dataSaverEnabled => _dataSaverEnabled;

  Future<void> _loadSettings() async {
    final prefs = await _getPrefs();
    final localeCode = prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(localeCode);
    _dataSaverEnabled = prefs.getBool(_dataSaverKey) ?? false;
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

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) {
      return;
    }

    _locale = locale;
    final prefs = await _getPrefs();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> setDataSaver(bool enabled) async {
    if (_dataSaverEnabled == enabled) {
      return;
    }

    _dataSaverEnabled = enabled;
    final prefs = await _getPrefs();
    await prefs.setBool(_dataSaverKey, enabled);
    notifyListeners();
  }
}
