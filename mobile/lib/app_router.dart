import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/pages/register_page.dart';
import 'package:mobile/pages/search_page.dart';
import 'package:mobile/widgets/navigation_scaffold.dart';

class AppRouter {
  AppRouter({required AuthService authService})
    : _authService = authService,
      _refreshListenable = _GoRouterRefreshStream(
        authService.authStateChanges,
      ) {
    router = GoRouter(
      initialLocation: '/auth',
      refreshListenable: _refreshListenable,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(path: '/auth', builder: (context, state) => const AuthGate()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              NavigationScaffold(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/',
                  builder: (context, state) => const HomePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/search',
                  builder: (context, state) => const SearchPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
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
  }

  final AuthService _authService;
  final _GoRouterRefreshStream _refreshListenable;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = _authService.isAuthenticated;
    final location = state.matchedLocation;

    final isPublicAuthPage =
        location == '/login' || location == '/register' || location == '/auth';

    if (!isAuthenticated && !isPublicAuthPage) {
      return '/login';
    }

    if (isAuthenticated && isPublicAuthPage) {
      return '/';
    }

    if (!isAuthenticated && location == '/auth') {
      return '/login';
    }

    return null;
  }

  void dispose() {
    _refreshListenable.dispose();
    router.dispose();
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
      onError: (_, __) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
