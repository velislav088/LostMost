import 'dart:async';

import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

abstract class MQTTClientAdapter {
  Future<void> connect();

  void disconnect();

  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce});

  void publishUtf8(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atMostOnce,
  });

  Stream<String> get payloadMessages;
}

class MqttServerClientAdapter implements MQTTClientAdapter {
  MqttServerClientAdapter({
    required MQTTConfig config,
    required String clientIdentifier,
  }) : _client = MqttServerClient.withPort(
         config.server,
         clientIdentifier,
         config.port,
       ) {
    _client.secure = true;
    _client.keepAlivePeriod = config.keepAliveSeconds;
    _client.connectionMessage = MqttConnectMessage()
      ..withClientIdentifier(clientIdentifier)
      ..authenticateAs(config.username, config.password)
      ..withWillQos(MqttQos.atMostOnce);
  }

  final MqttServerClient _client;
  final StreamController<String> _payloadMessagesController =
      StreamController<String>.broadcast();

  void Function()? _cancelUpdatesSubscription;

  @override
  Stream<String> get payloadMessages => _payloadMessagesController.stream;

  @override
  Future<void> connect() async {
    try {
      await _client.connect();
    } catch (_) {
      _client.disconnect();
      throw MQTTException('Failed to connect to MQTT broker.');
    }

    // The connection status may be null if the client is not connected.
    final status = _client.connectionStatus?.state;
    if (status != MqttConnectionState.connected) {
      _client.disconnect();
      throw MQTTException('MQTT connection was rejected by the broker.');
    }

    final updates = _client.updates;
    if (updates == null) {
      _client.disconnect();
      throw MQTTException('MQTT updates stream is unavailable.');
    }

    final updatesSubscription = updates.listen(
      _handleMqttMessages,
      onError: (Object error, StackTrace stackTrace) {
        if (_payloadMessagesController.isClosed) {
          return;
        }
        _payloadMessagesController.addError(
          MQTTException('MQTT stream error.'),
          stackTrace,
        );
      },
    );
    _cancelUpdatesSubscription = () {
      unawaited(updatesSubscription.cancel());
      _cancelUpdatesSubscription = null;
    };
  }

  void _handleMqttMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    if (_payloadMessagesController.isClosed) {
      return;
    }

    for (final message in messages) {
      final payloadMessage = message.payload;
      if (payloadMessage is! MqttPublishMessage) {
        continue;
      }

      final payloadBytes = payloadMessage.payload.message;
      final payloadString = MqttPublishPayload.bytesToStringAsString(
        payloadBytes,
      );

      _payloadMessagesController.add(payloadString);
    }
  }

  @override
  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    _client.subscribe(topic, qos);
  }

  @override
  void publishUtf8(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atMostOnce,
  }) {
    final builder = MqttClientPayloadBuilder()..addUTF8String(payload);
    final encodedPayload = builder.payload;
    if (encodedPayload == null) {
      throw MQTTException('Failed to encode MQTT payload.');
    }

    _client.publishMessage(topic, qos, encodedPayload);
  }

  void dispose() {
    _cancelUpdatesSubscription?.call();
    _cancelUpdatesSubscription = null;

    try {
      _client.disconnect();
    } catch (_) {}

    if (!_payloadMessagesController.isClosed) {
      _payloadMessagesController.close();
    }
  }

  @override
  void disconnect() => dispose();
}
