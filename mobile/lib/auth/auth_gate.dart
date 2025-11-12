/*

AUTH GATE - This will continuously listen for auth state changes.

--------------------------------------------------------------------------------------------------------------------------

unauthenticated -> Login Page
authenticated -> Profile Page

*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

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
          if (session != null) {
            context.go('/');
          } else {
            context.go('/login');
          }
        });
        return LoginPage();
      },
    );
  }
}
