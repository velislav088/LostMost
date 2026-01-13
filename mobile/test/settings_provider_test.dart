import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SettingsProvider loads defaults when no prefs set', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = SettingsProvider();
    // wait for async _loadSettings to complete
    await Future<void>.delayed(Duration.zero);

    expect(settings.locale, const Locale('en'));
    expect(settings.dataSaverEnabled, isFalse);
  });

  test('setLocale persists locale', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = SettingsProvider();
    await Future<void>.delayed(Duration.zero);

    await settings.setLocale(const Locale('bg'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'bg');
    expect(settings.locale.languageCode, 'bg');
  });

  test('setDataSaver persists value', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = SettingsProvider();
    await Future<void>.delayed(Duration.zero);

    await settings.setDataSaver(true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('data_saver'), isTrue);
    expect(settings.dataSaverEnabled, isTrue);
  });
}
