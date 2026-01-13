/*

AUTH GATE - This will continuously listen for auth state changes.

--------------------------------------------------------------------------------------------------------------------------

unauthenticated -> Login Page
authenticated -> Home Page

*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  // callback for auth status changes (used for testing)
  final void Function(bool authenticated)? onAuthChange;

  const AuthGate({super.key, this.onAuthChange});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder(
      // Listen to auth state changes from AuthService
      stream: authService.authStateChanges,

      // Build appropriate based on the auth state
      builder: (context, snapshot) {
        // loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // check if there is a valid session currently
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Schedule navigation after current build frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // If test provides an observer, use it and don't navigate.
          if (onAuthChange != null) {
            onAuthChange!(session != null);
            return;
          }

          if (session != null) {
            context.go('/');
          } else {
            context.go('/login');
          }
        });

        // return loader..
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
