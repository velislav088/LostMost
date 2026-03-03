import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

class MockMQTTService extends Mock implements MQTTService {}

void main() {
  late MockAuthService mockAuthService;
  late MockMQTTService mockMqttService;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    mockAuthService = MockAuthService();
    mockMqttService = MockMQTTService();

    when(
      () => mockAuthService.authStateChanges,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => mockMqttService.initialize()).thenAnswer((_) async {});
    when(
      () => mockMqttService.scanResultStream,
    ).thenAnswer((_) => const Stream.empty());
  });

  Widget buildRouterApp(AppRouter appRouter) => MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
      ),
      Provider<AuthService>.value(value: mockAuthService),
      Provider<MQTTService>.value(value: mockMqttService),
    ],
    child: MaterialApp.router(
      routerConfig: appRouter.router,
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en'), Locale('bg')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );

  testWidgets('unauthenticated users are redirected to login', (tester) async {
    when(() => mockAuthService.isAuthenticated).thenReturn(false);
    final appRouter = AppRouter(authService: mockAuthService);
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(buildRouterApp(appRouter));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    appRouter.router.go('/search');
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('authenticated users are redirected away from login', (
    tester,
  ) async {
    when(() => mockAuthService.isAuthenticated).thenReturn(true);
    final appRouter = AppRouter(authService: mockAuthService);
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(buildRouterApp(appRouter));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    appRouter.router.go('/login');
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });
}
