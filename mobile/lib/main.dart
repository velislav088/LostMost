import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/pages/register_page.dart';
import 'package:mobile/pages/search_page.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:mobile/widgets/navigation_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // load environment variables
    await dotenv.load(fileName: 'assets/.env');

    final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');
    final supabaseUrl = dotenv.get('SUPABASE_URL');

    // validate environment variables
    if (supabaseAnonKey.isEmpty || supabaseUrl.isEmpty) {
      throw Exception('Missing required environment variables');
    }

    // supabase setup
    await Supabase.initialize(anonKey: supabaseAnonKey, url: supabaseUrl);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          Provider(create: (_) => MQTTService()),
          Provider(create: (_) => AuthService()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    // handle fatal initialization errors
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/auth',
  routes: [
    // unauthorised pages
    GoRoute(path: '/auth', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // navbar routes
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          NavigationScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // get theme (light/dark)
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // use go_router and themes
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      locale: settingsProvider.locale,
      supportedLocales: const [Locale('en'), Locale('bg')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
