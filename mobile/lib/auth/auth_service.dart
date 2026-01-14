import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Allow injecting a custom Supabase client (used for testing);
  // fall back to the default global instance in production.
  final SupabaseClient _supabase;

  /// Creates an AuthService with optional custom Supabase client.
  AuthService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) =>
      _supabase.auth.signInWithPassword(email: email, password: password);

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(String email, String password) =>
      _supabase.auth.signUp(email: email, password: password);

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

  // Expose auth state change stream
  // Wrap Supabase's stream so UI can be dependant on AuthService.
  Stream get authStateChanges => _supabase.auth.onAuthStateChange;

  // Convenience stream of sessions only
  Stream<dynamic> get authSessions =>
      _supabase.auth.onAuthStateChange.map((e) => e.session);

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) =>
      _supabase.auth.updateUser(UserAttributes(password: newPassword));

  /// Reset password for email
  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
