import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService;

  ProfileViewModel({required AuthService authService})
    : _authService = authService {
    _init();
  }

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

  void _init() {
    _currentUserEmail = _authService.getCurrentUserEmail();
    _loadAppVersion();
    calculateCacheSize();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      notifyListeners();
    } catch (e) {
      _appVersion = 'Unknown';
      notifyListeners();
    }
  }

  Future<void> calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      var totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      _cacheSize = _formatBytes(totalSize);
    } catch (e) {
      _cacheSize = 'Unknown';
    }
    notifyListeners();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes < 1024) {
      return '$bytes B';
    }
    var value = bytes / 1;
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
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      await calculateCacheSize();
      return true;
    } catch (e) {
      _error = 'Failed to clear cache: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update password: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
