import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {}

class FakeAuthEvent {
  final dynamic session;
  FakeAuthEvent(this.session);
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
            onAuthChange: (auth) {
              result = auth;
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
            onAuthChange: (auth) {
              result = auth;
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
