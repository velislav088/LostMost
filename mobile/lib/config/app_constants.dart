class AppConstants {
  static const int mqttPort = 8883;
  static const String defaultDeviceId = 'esp32_001';
  static const int mqttKeepAlive = 20;
  static const Duration scanInterval = Duration(seconds: 10);

  static const int rssiNearbyThreshold = -80;
}
