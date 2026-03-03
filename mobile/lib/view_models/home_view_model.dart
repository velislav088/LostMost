import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/models/scan_result.dart';
import 'package:mobile/mqtt/mqtt_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required MQTTService mqttService})
    : _mqttService = mqttService;

  final MQTTService _mqttService;

  String? _error;
  bool _isInitializing = false;
  ScanResult? _latestScan;
  StreamSubscription<ScanResult>? _scanSubscription;
  Future<void>? _initializationTask;

  ScanResult? get latestScan => _latestScan;
  String? get error => _error;
  bool get isInitializing => _isInitializing;
  int? get latestRssi => _latestScan?.devices.isNotEmpty == true
      ? _latestScan!.devices.first.rssi
      : null;

  String? get currentRssi {
    final rssi = latestRssi;
    if (rssi != null) {
      return 'RSSI: $rssi';
    }
    return null;
  }

  Future<void> initialize() async {
    if (_isInitializing) {
      return _initializationTask ?? Future<void>.value();
    }

    final pendingTask = _initializationTask;
    if (pendingTask != null) {
      return pendingTask;
    }

    final task = _initializeInternal().whenComplete(() {
      _initializationTask = null;
    });
    _initializationTask = task;
    return task;
  }

  Future<void> _initializeInternal() async {
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      await _mqttService.initialize();

      _scanSubscription = _mqttService.scanResultStream.listen(
        (scanResult) {
          _latestScan = scanResult;
          _error = null;
          notifyListeners();
        },
        onError: (Object error, StackTrace _) {
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    await initialize();
  }

  @override
  void dispose() {
    final scanSubscription = _scanSubscription;
    _scanSubscription = null;
    if (scanSubscription != null) {
      unawaited(scanSubscription.cancel());
    }
    super.dispose();
  }
}
