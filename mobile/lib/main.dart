import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/pages/register_page.dart';
import 'package:mobile/pages/search_page.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:mobile/widgets/navigation_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load environment variables
  await dotenv.load(fileName: "assets/.env");

  final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');
  final supabaseUrl = dotenv.get('SUPABASE_URL');

  // supabase setup
  await Supabase.initialize(anonKey: supabaseAnonKey, url: supabaseUrl);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
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
      supportedLocales: const [
        Locale('en'),
        Locale('bg'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
