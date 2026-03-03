import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUserResponse extends Mock implements UserResponse {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthService authService;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);

    registerFallbackValue(UserAttributes());

    authService = AuthService(client: mockClient);
  });

  test('signInWithEmailPassword normalizes email before call', () async {
    when(
      () => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => MockAuthResponse());

    await authService.signInWithEmailPassword('  TEST@EXAMPLE.COM  ', 'secret');

    verify(
      () => mockAuth.signInWithPassword(
        email: 'test@example.com',
        password: 'secret',
      ),
    ).called(1);
  });

  test('signUpWithEmailPassword normalizes email before call', () async {
    when(
      () => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => MockAuthResponse());

    await authService.signUpWithEmailPassword('  NEW@TEST.COM ', 'pass456');

    verify(
      () => mockAuth.signUp(email: 'new@test.com', password: 'pass456'),
    ).called(1);
  });

  test('resetPasswordForEmail normalizes email before call', () async {
    when(() => mockAuth.resetPasswordForEmail(any())).thenAnswer((_) async {});

    await authService.resetPasswordForEmail(' USER@EMAIL.COM ');

    verify(() => mockAuth.resetPasswordForEmail('user@email.com')).called(1);
  });

  test('signOut calls Supabase signOut', () async {
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await authService.signOut();

    verify(() => mockAuth.signOut()).called(1);
  });

  test('getCurrentUserEmail returns email from current session', () {
    final session = MockSession();
    final user = MockUser();
    when(() => user.email).thenReturn('user@email.com');
    when(() => session.user).thenReturn(user);
    when(() => mockAuth.currentSession).thenReturn(session);

    expect(authService.getCurrentUserEmail(), 'user@email.com');
  });

  test('isAuthenticated is true when currentSession exists', () {
    when(() => mockAuth.currentSession).thenReturn(MockSession());
    expect(authService.isAuthenticated, isTrue);
  });

  test('isAuthenticated is false when currentSession is null', () {
    when(() => mockAuth.currentSession).thenReturn(null);
    expect(authService.isAuthenticated, isFalse);
  });

  test('authSessions maps AuthState to Session', () async {
    final session = MockSession();
    final controller = StreamController<AuthState>();
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

    final emitted = <Session?>[];
    final subscription = authService.authSessions.listen(emitted.add);

    controller.add(AuthState(AuthChangeEvent.signedIn, session));
    await Future<void>.delayed(Duration.zero);

    expect(emitted, <Session?>[session]);

    await subscription.cancel();
    await controller.close();
  });

  test('signInWithEmailPassword maps auth errors to safe message', () async {
    when(
      () => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthException('Invalid login credentials'));

    expect(
      () => authService.signInWithEmailPassword('fail@test.com', 'wrong'),
      throwsA(
        isA<AppAuthException>().having(
          (error) => error.message,
          'message',
          'Invalid email or password',
        ),
      ),
    );
  });

  test('signUpWithEmailPassword maps auth errors to safe message', () async {
    when(
      () => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthException('User already registered'));

    expect(
      () => authService.signUpWithEmailPassword('test@test.com', '123456'),
      throwsA(
        isA<AppAuthException>().having(
          (error) => error.message,
          'message',
          'Email is already registered',
        ),
      ),
    );
  });

  test(
    'signOut returns generic safe error for unexpected exceptions',
    () async {
      when(() => mockAuth.signOut()).thenThrow(Exception('internal details'));

      expect(
        () => authService.signOut(),
        throwsA(
          isA<AppAuthException>().having(
            (error) => error.message,
            'message',
            'Unable to sign out right now. Please try again.',
          ),
        ),
      );
    },
  );

  test('updatePassword passes request to Supabase client', () async {
    when(
      () => mockAuth.updateUser(any()),
    ).thenAnswer((_) async => MockUserResponse());

    await authService.updatePassword('newpass123');

    verify(() => mockAuth.updateUser(any())).called(1);
  });

  test('empty email throws validation exception', () async {
    expect(
      () => authService.signInWithEmailPassword('', 'pass'),
      throwsA(
        isA<AppAuthException>().having(
          (error) => error.message,
          'message',
          'Email and password are required.',
        ),
      ),
    );
  });

  test(
    'signInWithEmailPassword returns generic message on unknown error',
    () async {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('network down'));

      expect(
        () => authService.signInWithEmailPassword('a@b.com', '123456'),
        throwsA(
          isA<AppAuthException>().having(
            (error) => error.message,
            'message',
            'Unable to sign in right now. Please try again.',
          ),
        ),
      );
    },
  );

  test(
    'signUpWithEmailPassword returns generic message on unknown error',
    () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('network down'));

      expect(
        () => authService.signUpWithEmailPassword('a@b.com', '123456'),
        throwsA(
          isA<AppAuthException>().having(
            (error) => error.message,
            'message',
            'Unable to sign up right now. Please try again.',
          ),
        ),
      );
    },
  );

  test('updatePassword validates empty values', () async {
    expect(
      () => authService.updatePassword(''),
      throwsA(
        isA<AppAuthException>().having(
          (error) => error.message,
          'message',
          'Password cannot be empty.',
        ),
      ),
    );
    verifyNever(() => mockAuth.updateUser(any()));
  });

  test('resetPasswordForEmail validates empty values', () async {
    expect(
      () => authService.resetPasswordForEmail(''),
      throwsA(
        isA<AppAuthException>().having(
          (error) => error.message,
          'message',
          'Email is required.',
        ),
      ),
    );
    verifyNever(() => mockAuth.resetPasswordForEmail(any()));
  });

  test('updatePassword maps auth exception message', () async {
    when(
      () => mockAuth.updateUser(any()),
    ).thenThrow(const AuthException('Password should contain'));

    expect(
      () => authService.updatePassword('123456'),
      throwsA(
        isA<AppAuthException>().having(
          (error) => error.message,
          'message',
          'Password does not meet security requirements',
        ),
      ),
    );
  });
}
