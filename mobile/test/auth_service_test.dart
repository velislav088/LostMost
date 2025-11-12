import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/auth/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

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

  test('signInWithEmailPassword throws error on failed sign-in', () async {
    when(
      () => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Failed login'));

    expect(
      () => authService.signInWithEmailPassword('fail@test.com', 'wrongpass'),
      throwsA(isA<Exception>()),
    );

    verify(
      () => mockAuth.signInWithPassword(
        email: 'fail@test.com',
        password: 'wrongpass',
      ),
    ).called(1);
  });

  test('signUpWithEmailPassword throws error on failed sign-up', () async {
    when(
      () => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Failed sign-up'));

    expect(
      () => authService.signUpWithEmailPassword('fail@test.com', 'pass123'),
      throwsA(isA<Exception>()),
    );

    verify(
      () => mockAuth.signUp(email: 'fail@test.com', password: 'pass123'),
    ).called(1);
  });

  test('getCurrentUserEmail returns null if there is no current session', () {
    when(() => mockAuth.currentSession).thenReturn(null);

    final email = authService.getCurrentUserEmail();
    expect(email, isNull);
  });
}
