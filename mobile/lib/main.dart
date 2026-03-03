import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/app_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/config/runtime_config.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final runtimeConfig = await RuntimeConfig.load();

    await Supabase.initialize(
      anonKey: runtimeConfig.supabaseAnonKey,
      url: runtimeConfig.supabaseUrl,
    );

    final authService = AuthService();
    final mqttService = MQTTService(
      config: MQTTConfig(
        server: runtimeConfig.mqttServer,
        username: runtimeConfig.mqttUsername,
        password: runtimeConfig.mqttPassword,
      ),
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          Provider<AuthService>.value(value: authService),
          Provider<MQTTService>(
            create: (_) => mqttService,
            dispose: (_, service) => service.dispose(),
          ),
        ],
        child: MyApp(authService: authService),
      ),
    );
  } catch (error) {
    runApp(BootstrapErrorApp(message: _bootstrapErrorMessage(error)));
  }
}

String _bootstrapErrorMessage(Object error) {
  if (!kDebugMode) {
    return 'Initialization failed. Please contact support.';
  }
  return 'Initialization failed: $error';
}

class MyApp extends StatefulWidget {
  const MyApp({required this.authService, super.key});

  final AuthService authService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(authService: widget.authService);

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (provider) => provider.themeMode,
    );
    final locale = context.select<SettingsProvider, Locale>(
      (provider) => provider.locale,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _appRouter.router,
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('bg')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Initialization Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
