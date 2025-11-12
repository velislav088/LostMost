import 'package:flutter/material.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/pages/register_page.dart';
import 'package:mobile/pages/search_page.dart';
import 'package:mobile/widgets/navigation_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

void main() async {
  // supabase setup
  await Supabase.initialize(
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyZ25zaHNvZ2l4Y215dW9pdHFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0Mjg1MzEsImV4cCI6MjA3ODAwNDUzMX0.ndi_l6YeNslAs3QvA-7i5a0qjZW4-4_YNYdCU--ffao',
    url: 'https://srgnshsogixcmyuoitqh.supabase.co',
  );
  runApp(MyApp());
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
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ), // home page
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(), // search page
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(), // profile page
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
    // use go_router
    return MaterialApp.router(routerConfig: _router);
  }
}
