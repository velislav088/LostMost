import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ThemeProvider loads saved theme', () async {
    SharedPreferences.setMockInitialValues({'theme_option': 'dark'});

    final theme = ThemeProvider();
    await Future<void>.delayed(Duration.zero);

    expect(theme.themeOption, ThemeOption.dark);
  });

  test('setThemeOption persists value', () async {
    SharedPreferences.setMockInitialValues({});

    final theme = ThemeProvider();
    await Future<void>.delayed(Duration.zero);

    await theme.setThemeOption(ThemeOption.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_option'), 'light');
    expect(theme.themeOption, ThemeOption.light);
  });
}
