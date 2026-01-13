import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockMQTTService extends Mock implements MQTTService {}

void main() {
  late MockMQTTService mockMQTT;
  late StreamController<String> controller;

  setUp(() {
    mockMQTT = MockMQTTService();
    controller = StreamController<String>();
    when(() => mockMQTT.initialize()).thenAnswer((_) async {});
    when(() => mockMQTT.rssiStream).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  Widget createWidgetUnderTest(Widget child) {
    final mockSettingsProvider = SettingsProvider();
    final mockThemeProvider = ThemeProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        Provider<MQTTService>.value(value: mockMQTT),
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
  }

  testWidgets('HomePage shows RSSI updates from MQTTService', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest(const HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Connecting...'), findsOneWidget);

    // emit rssi
    controller.add('RSSI: -50');
    await tester.pumpAndSettle();

    expect(find.text('RSSI: -50'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
