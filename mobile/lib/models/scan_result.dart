import 'package:mobile/models/device.dart';

class ScanResult {
  final String deviceId; // ESP32 device ID
  final List<Device> devices;
  final DateTime timestamp;

  ScanResult({
    required this.deviceId,
    required this.devices,
    required this.timestamp,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final devicesList =
        (json['devices'] as List<dynamic>?)
            ?.map((e) => Device.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ScanResult(
      deviceId: json['scannerId'] as String? ?? 'unknown',
      devices: devicesList,
      timestamp: DateTime.now(), // or parse from json if available
    );
  }
}
