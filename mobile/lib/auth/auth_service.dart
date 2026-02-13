import 'package:supabase_flutter/supabase_flutter.dart';

class AppAuthException implements Exception {
  AppAuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthService {
  // Allow injecting a custom Supabase client (used for testing);
  // fall back to the default global instance in production.
  final SupabaseClient _supabase;

  /// Creates an AuthService with optional custom Supabase client.
  AuthService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AppAuthException(_parseAuthError(e.message), code: e.message);
    } catch (e) {
      throw AppAuthException('Failed to sign in: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AppAuthException(_parseAuthError(e.message), code: e.message);
    } catch (e) {
      throw AppAuthException('Failed to sign up: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppAuthException('Failed to sign out: ${e.toString()}');
    }
  }

  // Get user email
  String? getCurrentUserEmail() {
    try {
      final session = _supabase.auth.currentSession;
      final user = session?.user;
      return user?.email;
    } catch (e) {
      throw AppAuthException(
        'Failed to get current user email: ${e.toString()}',
      );
    }
  }

  // Expose auth state change stream
  // Wrap Supabase's stream so UI can be dependant on AuthService.
  Stream get authStateChanges => _supabase.auth.onAuthStateChange;

  // Convenience stream of sessions only
  Stream<dynamic> get authSessions =>
      _supabase.auth.onAuthStateChange.map((e) => e.session);

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AppAuthException('Failed to update password: ${e.toString()}');
    }
  }

  /// Reset password for email
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AppAuthException('Failed to send reset email: ${e.toString()}');
    }
  }

  /// Parse Supabase auth errors to more normal looking messages
  String _parseAuthError(String message) => switch (message) {
      _ when message.contains('Invalid login credentials') =>
        'Invalid email or password',
      _ when message.contains('User already registered') =>
        'Email is already registered',
      _ when message.contains('Password should be at least') =>
        'Password must be at least 6 characters',
      _ when message.contains('Unable to validate email') =>
        'Invalid email format',
      _ when message.contains('Signup disabled') =>
        'Signups are currently disabled',
      _ => message,
    };
}