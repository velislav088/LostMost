import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Allow injecting a custom Supabase client (used for testing);
  // fall back to the default global instance in production.
  final SupabaseClient _supabase;

  AuthService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  // FIXME: Authentication doesn't work on first try and the app needs a hot restart - after there's no problems.
  // UPDATE: Should be fixed now, might've been a caching bug from the device.

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
