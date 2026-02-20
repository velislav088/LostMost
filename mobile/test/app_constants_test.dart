import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/app_constants.dart';

void main() {
  test('RSSI thresholds are ordered correctly', () {
    expect(AppConstants.rssiCloseThreshold,
        greaterThan(AppConstants.rssiNearbyThreshold));
  });

  test('Default values are reasonable', () {
    expect(AppConstants.mqttPort, isNonZero);
    expect(AppConstants.defaultDeviceId, isNotEmpty);
    expect(AppConstants.mqttKeepAlive, isPositive);
    expect(AppConstants.scanInterval.inSeconds, greaterThan(0));
  });
}
