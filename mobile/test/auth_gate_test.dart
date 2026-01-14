import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {}

class FakeAuthEvent {
  FakeAuthEvent(this.session);
  final dynamic session;
}

void main() {
  late MockAuthService mockAuth;

  setUp(() {
    mockAuth = MockAuthService();
  });

  testWidgets('AuthGate calls onAuthChange(true) when session present', (
    tester,
  ) async {
    when(
      () => mockAuth.authStateChanges,
    ).thenAnswer((_) => Stream.value(FakeAuthEvent('session')));

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

    // Allow post-frame callbacks to run
    await tester.pump();
    await tester.pump();

    expect(result, isTrue);
  });

  testWidgets('AuthGate calls onAuthChange(false) when no session', (
    tester,
  ) async {
    when(
      () => mockAuth.authStateChanges,
    ).thenAnswer((_) => Stream.value(FakeAuthEvent(null)));

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

    // Allow post-frame callbacks to run
    await tester.pump();
    await tester.pump();

    expect(result, isFalse);
  });
}
