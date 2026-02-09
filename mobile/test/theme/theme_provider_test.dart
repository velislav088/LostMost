import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeProvider initializes with defaults', () async {
    final provider = ThemeProvider();
    await Future.delayed(Duration.zero);

    expect(provider.themeOption, ThemeOption.system);
    expect(provider.themeMode, ThemeMode.system);
  });

  test('setThemeOption updates theme and persists', () async {
    final provider = ThemeProvider();
    await Future.delayed(Duration.zero);

    await provider.setThemeOption(ThemeOption.dark);
    expect(provider.themeOption, ThemeOption.dark);
    expect(provider.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_option'), 'dark');
  });

  test('loading existing preference works', () async {
    SharedPreferences.setMockInitialValues({'theme_option': 'light'});

    final provider = ThemeProvider();
    await Future.delayed(Duration.zero);

    expect(provider.themeOption, ThemeOption.light);
  });
}
