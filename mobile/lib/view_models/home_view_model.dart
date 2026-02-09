import 'package:flutter/material.dart';
import 'package:mobile/models/scan_result.dart';
import 'package:mobile/mqtt/mqtt_service.dart';

class HomeViewModel extends ChangeNotifier {
  final MQTTService _mqttService;
  ScanResult? _latestScan;
  String? _error;
  bool _isInitializing = false;

  HomeViewModel({required MQTTService mqttService})
    : _mqttService = mqttService;

  ScanResult? get latestScan => _latestScan;
  String? get error => _error;
  bool get isInitializing => _isInitializing;

  // Helper to get RSSI of the first device for the current UI
  String? get currentRssi {
    if (_latestScan != null && _latestScan!.devices.isNotEmpty) {
      return 'RSSI: ${_latestScan!.devices.first.rssi}';
    }
    return null;
  }

  Future<void> initialize() async {
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _mqttService.initialize();

      _mqttService.scanResultStream.listen(
        (scanResult) {
          _latestScan = scanResult;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void retry() {
    initialize();
  }

  // Expose disposing logic if needed, but Provider handles disposal of the ViewModel using 'dispose' callback
  @override
  void dispose() {
    // _mqttService.dispose(); // Do NOT dispose service here if it's provided globally!
    super.dispose();
  }
}
