import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/view_models/profile_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUserResponse extends Mock implements UserResponse {}

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  MockPathProviderPlatform(this.tempDirectory);

  final Directory tempDirectory;

  @override
  Future<String?> getTemporaryPath() async => tempDirectory.path;
}

void main() {
  late MockAuthService mockAuthService;
  late ProfileViewModel viewModel;
  late Directory tempDirectory;

  setUp(() async {
    mockAuthService = MockAuthService();
    when(
      () => mockAuthService.getCurrentUserEmail(),
    ).thenReturn('test@test.com');
    when(
      () => mockAuthService.updatePassword(any()),
    ).thenAnswer((_) async => MockUserResponse());

    PackageInfo.setMockInitialValues(
      appName: 'LostMost',
      packageName: 'com.example.mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    tempDirectory = Directory.systemTemp.createTempSync('profile_vm_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDirectory);
    viewModel = ProfileViewModel(authService: mockAuthService);
    await viewModel.initialization;
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('initialization loads email and app version', () {
    expect(viewModel.currentUserEmail, 'test@test.com');
    expect(viewModel.appVersion, '1.0.0');
    expect(viewModel.error, isNull);
  });

  test('calculateCacheSize updates cacheSize', () async {
    await viewModel.calculateCacheSize();

    expect(viewModel.cacheSize, isNot('Calculating...'));
    expect(viewModel.cacheSize, isNotEmpty);
  });

  test('clearCache returns true and clears errors', () async {
    final cacheFile = File('${tempDirectory.path}/cache.txt')
      ..writeAsStringSync('cached-data');
    expect(cacheFile.existsSync(), isTrue);

    final result = await viewModel.clearCache();

    expect(result, isTrue);
    expect(viewModel.error, isNull);
    expect(cacheFile.existsSync(), isFalse);
  });

  test('updatePassword rejects short passwords', () async {
    final result = await viewModel.updatePassword('123');

    expect(result, isFalse);
    expect(viewModel.error, 'Password must be at least 6 characters.');
    verifyNever(() => mockAuthService.updatePassword(any()));
  });

  test('updatePassword success clears loading and error', () async {
    final result = await viewModel.updatePassword('123456');

    expect(result, isTrue);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.error, isNull);
    verify(() => mockAuthService.updatePassword('123456')).called(1);
  });

  test('updatePassword handles AppAuthException', () async {
    when(
      () => mockAuthService.updatePassword(any()),
    ).thenThrow(AppAuthException('Unable to update.'));

    final result = await viewModel.updatePassword('123456');

    expect(result, isFalse);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.error, 'Unable to update.');
  });

  test('updatePassword handles generic failures', () async {
    when(
      () => mockAuthService.updatePassword(any()),
    ).thenThrow(Exception('unknown'));

    final result = await viewModel.updatePassword('123456');

    expect(result, isFalse);
    expect(viewModel.error, 'Failed to update password.');
  });

  test('logout delegates to auth service', () async {
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});

    await viewModel.logout();

    verify(() => mockAuthService.signOut()).called(1);
  });
}
