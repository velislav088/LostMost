import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  // get broker env variables
  static String get mqttServer => dotenv.get('MQTT_SERVER');
  static String get mqttUsername => dotenv.get('MQTT_USERNAME');
  static String get mqttPassword => dotenv.get('MQTT_PASSWORD');

  // default broker settings (for now)
  static const int mqttPort = 8883;
  static const String deviceId = 'esp32_001';

  late MqttServerClient _client;
  final _rssiController = StreamController<String>.broadcast();
  Stream<String> get rssiStream => _rssiController.stream;

  Timer? _scanTimer;

  /// Sets up MQTT connection and starts listening for updates
  Future<void> initialize() async {
    _client = MqttServerClient.withPort(
      mqttServer,
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      mqttPort,
    );
    _client.secure = true;
    _client.keepAlivePeriod = 20;

    final connMsg = MqttConnectMessage()
      ..withClientIdentifier(
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      )
      ..authenticateAs(mqttUsername, mqttPassword)
      ..withWillQos(MqttQos.atMostOnce);

    _client.connectionMessage = connMsg;

    // attempt to connect to client..
    try {
      await _client.connect();
    } catch (e) {
      _client.disconnect();
      rethrow;
    }

    // broker topics
    const resultsTopic = 'ble/scanner/$deviceId/results';
    const commandsTopic = 'ble/scanner/$deviceId/commands';

    // subscribe to broker
    _client.subscribe(resultsTopic, MqttQos.atMostOnce);

    final updates = _client.updates;
    if (updates == null) {
      return;
    }

    updates.listen((c) {
      for (final message in c) {
        final payload = (message.payload as MqttPublishMessage).payload.message;
        final payloadString = MqttPublishPayload.bytesToStringAsString(payload);
        final data = jsonDecode(payloadString) as Map<String, dynamic>;

        // check if any devices are found
        final devices = data['devices'] as List<dynamic>?;
        if (devices != null && devices.isNotEmpty) {
          final rssiValue = devices[0]['rssi'].toString();
          _rssiController.add('RSSI: $rssiValue');
        } else {
          _rssiController.add('No devices found');
        }
      }
    });

    // Send request every 10 seconds
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final requestId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      final scanMessage = jsonEncode({
        'action': 'scan',
        'requestId': requestId,
      });
      final builder = MqttClientPayloadBuilder()..addUTF8String(scanMessage);
      final payload = builder.payload;
      if (payload != null) {
        _client.publishMessage(commandsTopic, MqttQos.atMostOnce, payload);
      }
    });
  }

  void dispose() {
    _scanTimer?.cancel();
    _client.disconnect();
    _rssiController.close();
  }
}
