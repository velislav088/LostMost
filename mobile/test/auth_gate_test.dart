import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSession extends Mock implements Session {}

void main() {
  late MockAuthService mockAuth;

  setUp(() {
    mockAuth = MockAuthService();
  });

  testWidgets('AuthGate calls onAuthChange(true) when session present', (
    tester,
  ) async {
    final session = MockSession();
    when(() => mockAuth.currentSession).thenReturn(session);
    when(() => mockAuth.authStateChanges).thenAnswer(
      (_) =>
          Stream<AuthState>.value(AuthState(AuthChangeEvent.signedIn, session)),
    );

    bool? result;

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: mockAuth,
        child: MaterialApp(
          home: AuthGate(
            onAuthChange: ({required bool isAuthenticated}) {
              result = isAuthenticated;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(result, isTrue);
  });

  testWidgets('AuthGate calls onAuthChange(false) when no session', (
    tester,
  ) async {
    when(() => mockAuth.currentSession).thenReturn(null);
    when(() => mockAuth.authStateChanges).thenAnswer(
      (_) => Stream<AuthState>.value(
        const AuthState(AuthChangeEvent.signedOut, null),
      ),
    );

    bool? result;

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: mockAuth,
        child: MaterialApp(
          home: AuthGate(
            onAuthChange: ({required bool isAuthenticated}) {
              result = isAuthenticated;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(result, isFalse);
  });
}
