import 'package:supabase_flutter/supabase_flutter.dart';

class AppAuthException implements Exception {
  AppAuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _supabase;

  AuthService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;

  bool get isAuthenticated => currentSession != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Stream<Session?> get authSessions =>
      authStateChanges.map((event) => event.session);

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw AppAuthException('Email and password are required.');
    }

    try {
      return await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
    } on AuthException catch (e) {
      throw AppAuthException(_parseAuthError(e.message), code: e.message);
    } catch (_) {
      throw AppAuthException('Unable to sign in right now. Please try again.');
    }
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw AppAuthException('Email and password are required.');
    }

    try {
      return await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
    } on AuthException catch (e) {
      throw AppAuthException(_parseAuthError(e.message), code: e.message);
    } catch (_) {
      throw AppAuthException('Unable to sign up right now. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      throw AppAuthException('Unable to sign out right now. Please try again.');
    }
  }

  String? getCurrentUserEmail() {
    final user = currentSession?.user;
    return user?.email;
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    if (newPassword.isEmpty) {
      throw AppAuthException('Password cannot be empty.');
    }

    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw AppAuthException(_parseAuthError(e.message), code: e.message);
    } catch (_) {
      throw AppAuthException(
        'Unable to update password right now. Please try again.',
      );
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      throw AppAuthException('Email is required.');
    }

    try {
      await _supabase.auth.resetPasswordForEmail(normalizedEmail);
    } on AuthException catch (e) {
      throw AppAuthException(_parseAuthError(e.message), code: e.message);
    } catch (_) {
      throw AppAuthException(
        'Unable to send reset email right now. Please try again.',
      );
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

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
    _ when message.contains('Password should contain') =>
      'Password does not meet security requirements',
    _ when message.contains('For security purposes') =>
      'Please wait before trying again',
    _ => message,
  };
}
