import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/register_page.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSettingsProvider extends Mock implements SettingsProvider {}

class MockThemeProvider extends Mock implements ThemeProvider {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockSettingsProvider mockSettingsProvider;
  late MockThemeProvider mockThemeProvider;
  late MockAuthService mockAuthService;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockThemeProvider = MockThemeProvider();
    mockAuthService = MockAuthService();

    when(() => mockSettingsProvider.locale).thenReturn(const Locale('en'));
    when(() => mockThemeProvider.themeOption).thenReturn(ThemeOption.system);
  });

  Widget createWidgetUnderTest(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(
        value: mockSettingsProvider,
      ),
      ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
      Provider<AuthService>.value(value: mockAuthService),
    ],
    child: MaterialApp(
      home: child,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('bg')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );

  testWidgets('LoginPage renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(const LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('RegisterPage renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(const RegisterPage()));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
