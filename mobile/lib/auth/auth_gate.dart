import 'package:flutter/material.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.onAuthChange});

  final void Function({required bool isAuthenticated})? onAuthChange;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? authService.currentSession;
        onAuthChange?.call(isAuthenticated: session != null);
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
