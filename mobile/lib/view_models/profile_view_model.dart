import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required AuthService authService})
    : _authService = authService,
      initialization = Future<void>.value() {
    initialization = _initialize();
  }

  final AuthService _authService;

  late Future<void> initialization;

  String _cacheSize = 'Calculating...';
  String _appVersion = '...';
  String? _currentUserEmail;
  bool _isLoading = false;
  String? _error;

  String get cacheSize => _cacheSize;
  String get appVersion => _appVersion;
  String? get currentUserEmail => _currentUserEmail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _initialize() async {
    _currentUserEmail = _authService.getCurrentUserEmail();
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      _loadAppVersion(),
      calculateCacheSize(),
    ]);
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (_) {
      _appVersion = 'Unknown';
    }
    notifyListeners();
  }

  Future<void> calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final totalSize = await Isolate.run<int>(
        () => _calculateDirectorySizeSync(tempDir.path),
      );
      _cacheSize = _formatBytes(totalSize);
      _error = null;
    } catch (_) {
      _cacheSize = 'Unknown';
      _error = 'Failed to calculate cache size.';
    }
    notifyListeners();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const suffixes = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes < 1024) {
      return '$bytes B';
    }

    var value = bytes.toDouble();
    var suffixIndex = 0;

    while (value >= 1024 && suffixIndex < suffixes.length - 1) {
      value /= 1024;
      suffixIndex++;
    }

    return '${value.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  Future<bool> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await Isolate.run<void>(() => _clearDirectoryContentsSync(tempDir.path));

      await calculateCacheSize();
      _error = null;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to clear cache.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    final trimmedPassword = newPassword.trim();
    if (trimmedPassword.length < 6) {
      _error = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updatePassword(trimmedPassword);
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } on AppAuthException catch (error) {
      _isLoading = false;
      _error = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isLoading = false;
      _error = 'Failed to update password.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}

int _calculateDirectorySizeSync(String directoryPath) {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    return 0;
  }

  var totalSize = 0;
  for (final entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }

    try {
      totalSize += entity.lengthSync();
    } catch (_) {}
  }

  return totalSize;
}

void _clearDirectoryContentsSync(String directoryPath) {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    return;
  }

  for (final entity in directory.listSync(followLinks: false)) {
    try {
      entity.deleteSync(recursive: true);
    } catch (_) {}
  }
}
