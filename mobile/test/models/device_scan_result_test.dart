import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/device.dart';
import 'package:mobile/models/scan_result.dart';

void main() {
  group('Device.fromJson', () {
    test('parses full JSON correctly', () {
      final json = {
        'id': 'dev1',
        'name': 'Tag 1',
        'rssi': -42,
        'metadata': {'foo': 'bar'},
      };
      final device = Device.fromJson(json);
      expect(device.id, 'dev1');
      expect(device.name, 'Tag 1');
      expect(device.rssi, -42);
      expect(device.metadata['foo'], 'bar');
    });

    test('uses defaults when keys missing', () {
      final device = Device.fromJson({});
      expect(device.id, 'unknown');
      expect(device.name, 'Unknown Device');
      expect(device.rssi, 0);
      expect(device.metadata, isEmpty);
    });
  });

  group('ScanResult.fromJson', () {
    test('parses list of devices', () {
      final json = {
        'scannerId': 'scanner_x',
        'devices': [
          {'id': 'a', 'name': 'A', 'rssi': -10},
          {'id': 'b', 'name': 'B', 'rssi': -20},
        ],
      };

      final result = ScanResult.fromJson(json);
      expect(result.deviceId, 'scanner_x');
      expect(result.devices.length, 2);
      expect(result.devices[0].id, 'a');
    });

    test('handles missing devices gracefully', () {
      final result = ScanResult.fromJson({'scannerId': 'foo'});
      expect(result.deviceId, 'foo');
      expect(result.devices, isEmpty);
    });

    test('defaults unknown scannerId', () {
      final result = ScanResult.fromJson({});
      expect(result.deviceId, 'unknown');
    });
  });
}
