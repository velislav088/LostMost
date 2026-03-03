import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/app_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/models/scan_result.dart';
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

Future<void> completedVoid(Invocation _) => Future<void>.value();
Stream<ScanResult> emptyScanResultStream(Invocation _) =>
    const Stream<ScanResult>.empty();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('auth redirect flow smoke test', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final mockAuthService = MockAuthService();
    final mockMqttService = MockMQTTService();
    final authStateController = StreamController<AuthState>.broadcast();
    addTearDown(authStateController.close);

    when(() => mockAuthService.isAuthenticated).thenReturn(false);
    when(
      () => mockAuthService.authStateChanges,
    ).thenReturn(authStateController.stream);
    when(mockMqttService.initialize).thenAnswer(completedVoid);
    when(
      () => mockMqttService.scanResultStream,
    ).thenAnswer(emptyScanResultStream);

    final appRouter = AppRouter(authService: mockAuthService);
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(
      MultiProvider(
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
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    when(() => mockAuthService.isAuthenticated).thenReturn(true);
    authStateController.add(const AuthState(AuthChangeEvent.signedIn, null));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
