import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SettingsProvider initializes with defaults', () async {
    final provider = SettingsProvider();
    // wait for async init
    await Future.delayed(Duration.zero);

    expect(provider.locale, const Locale('en'));
    expect(provider.dataSaverEnabled, false);
  });

  test('setLocale updates locale and persists', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);

    await provider.setLocale(const Locale('bg'));
    expect(provider.locale, const Locale('bg'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'bg');
  });

  test('setDataSaver updates preference and persists', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);

    await provider.setDataSaver(true);
    expect(provider.dataSaverEnabled, true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('data_saver'), true);
  });
}
