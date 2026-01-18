import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  // Setup mock data
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthService authService;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);

    // Register fallback value for UserAttributes.
    registerFallbackValue(UserAttributes());

    authService = AuthService(client: mockClient);
  });

  test('signInWithEmailPassword calls the right Supabase method', () async {
    final mockResponse = MockAuthResponse();
    when(
      () => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => mockResponse);

    await authService.signInWithEmailPassword(
      'test@example.com',
      'password123',
    );

    verify(
      () => mockAuth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      ),
    ).called(1);
  });

  test('signUpWithEmailPassword works properly', () async {
    when(
      () => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => MockAuthResponse());

    await authService.signUpWithEmailPassword('newuser@test.com', 'pass456');

    verify(
      () => mockAuth.signUp(email: 'newuser@test.com', password: 'pass456'),
    ).called(1);
  });

  test('signOut calls Supabase signOut', () async {
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await authService.signOut();

    verify(() => mockAuth.signOut()).called(1);
  });

  test('getCurrentUserEmail returns the email from current session', () {
    final mockSession = MockSession();
    final mockUser = MockUser();

    when(() => mockUser.email).thenReturn('user@email.com');
    when(() => mockSession.user).thenReturn(mockUser);
    when(() => mockAuth.currentSession).thenReturn(mockSession);

    final email = authService.getCurrentUserEmail();

    expect(email, 'user@email.com');
  });

  test(
    'signInWithEmailPassword throws AppAuthException on failed sign-in',
    () async {
      const supabaseException = AuthException('Invalid login credentials');
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(supabaseException);

      expect(
        () => authService.signInWithEmailPassword('fail@test.com', 'wrongpass'),
        throwsA(isA<AppAuthException>()),
      );
    },
  );

  test(
    'signUpWithEmailPassword throws AppAuthException on failed sign-up',
    () async {
      const supabaseException = AuthException('User already registered');
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(supabaseException);

      expect(
        () => authService.signUpWithEmailPassword(
          'existing@test.com',
          'password123',
        ),
        throwsA(isA<AppAuthException>()),
      );
    },
  );

  test('signOut throws AppAuthException on error', () async {
    when(() => mockAuth.signOut()).thenThrow(Exception('Sign out failed'));

    expect(() => authService.signOut(), throwsA(isA<AppAuthException>()));
  });

  test('updatePassword throws AppAuthException on error', () async {
    when(
      () => mockAuth.updateUser(any()),
    ).thenThrow(Exception('Failed to update'));

    expect(
      () => authService.updatePassword('newpass123'),
      throwsA(isA<AppAuthException>()),
    );
  });

  test('resetPasswordForEmail throws AppAuthException on error', () async {
    when(
      () => mockAuth.resetPasswordForEmail(any()),
    ).thenThrow(Exception('Reset failed'));

    expect(
      () => authService.resetPasswordForEmail('user@email.com'),
      throwsA(isA<AppAuthException>()),
    );
  });

  test('getCurrentUserEmail returns null if there is no current session', () {
    when(() => mockAuth.currentSession).thenReturn(null);

    final email = authService.getCurrentUserEmail();
    expect(email, isNull);
  });
}
