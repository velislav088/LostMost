import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile/config/app_constants.dart';
import 'package:mobile/models/scan_result.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTException implements Exception {
  MQTTException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MQTTService {
  // get broker env variables
  static String get mqttServer => dotenv.get('MQTT_SERVER');
  static String get mqttUsername => dotenv.get('MQTT_USERNAME');
  static String get mqttPassword => dotenv.get('MQTT_PASSWORD');

  late MqttServerClient _client;
  final _scanResultController = StreamController<ScanResult>.broadcast();
  Stream<ScanResult> get scanResultStream => _scanResultController.stream;

  Timer? _scanTimer;
  bool _isInitialized = false;
  bool _isConnected = false;

  /// Sets up MQTT connection and starts listening for updates
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _client = MqttServerClient.withPort(
        mqttServer,
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
        AppConstants.mqttPort,
      );
      _client.secure = true;
      _client.keepAlivePeriod = AppConstants.mqttKeepAlive;

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
        throw MQTTException(
          'Failed to connect to MQTT broker: ${e.toString()}',
        );
      }

      _isConnected = true;

      // broker topics
      const resultsTopic =
          'ble/scanner/${AppConstants.defaultDeviceId}/results';
      const commandsTopic =
          'ble/scanner/${AppConstants.defaultDeviceId}/commands';

      // subscribe to broker
      _client.subscribe(resultsTopic, MqttQos.atMostOnce);

      final updates = _client.updates;
      if (updates == null) {
        throw MQTTException('Failed to get MQTT updates stream');
      }

      // listen to updates from broker
      updates.listen(
        (c) {
          try {
            for (final message in c) {
              final payload =
                  (message.payload as MqttPublishMessage).payload.message;
              final payloadString = MqttPublishPayload.bytesToStringAsString(
                payload,
              );
              final data = jsonDecode(payloadString) as Map<String, dynamic>;

              try {
                final result = ScanResult.fromJson(data);
                _scanResultController.add(result);
              } catch (e) {
                // If parsing fails for ScanResult, we might want to log it but not crash the stream
              }
            }
          } catch (e) {
            _scanResultController.addError(
              'Error parsing MQTT message: ${e.toString()}',
            );
          }
        },
        onError: (error) {
          _scanResultController.addError(
            'MQTT stream error: ${error.toString()}',
          );
        },
      );

      // Send request every 10 seconds
      _scanTimer = Timer.periodic(AppConstants.scanInterval, (_) {
        try {
          final requestId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
          final scanMessage = jsonEncode({
            'action': 'scan',
            'requestId': requestId,
          });
          final builder = MqttClientPayloadBuilder()
            ..addUTF8String(scanMessage);
          final payload = builder.payload;
          if (payload != null) {
            _client.publishMessage(commandsTopic, MqttQos.atMostOnce, payload);
          }
        } catch (e) {
          _scanResultController.addError(
            'Error sending scan request: ${e.toString()}',
          );
        }
      });

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      _isConnected = false;
      if (e is MQTTException) {
        rethrow;
      }
      throw MQTTException('Failed to initialize MQTT: ${e.toString()}');
    }
  }

  void dispose() {
    _scanTimer?.cancel();
    if (_isConnected) {
      try {
        _client.disconnect();
      } catch (e) {
        // ignore errors during disconnect
      }
      _isConnected = false;
    }
    if (!_scanResultController.isClosed) {
      _scanResultController.close();
    }
    _isInitialized = false;
  }
}
