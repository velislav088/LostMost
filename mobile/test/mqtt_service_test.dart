import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/app_constants.dart';
import 'package:mobile/mqtt/mqtt_client_adapter.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';

class FakeMqttClientAdapter implements MQTTClientAdapter {
  int connectCalls = 0;
  int disconnectCalls = 0;
  bool throwOnConnect = false;
  bool throwOnPublish = false;

  final StreamController<String> _payloadController =
      StreamController<String>.broadcast();
  final List<String> subscribedTopics = <String>[];
  final List<PublishedMessage> publishedMessages = <PublishedMessage>[];

  @override
  Stream<String> get payloadMessages => _payloadController.stream;

  @override
  Future<void> connect() async {
    connectCalls++;
    if (throwOnConnect) {
      throw MQTTException('connect failed');
    }
  }

  @override
  void disconnect() {
    disconnectCalls++;
    if (!_payloadController.isClosed) {
      _payloadController.close();
    }
  }

  @override
  void publishUtf8(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atMostOnce,
  }) {
    if (throwOnPublish) {
      throw MQTTException('publish failed');
    }
    publishedMessages.add(PublishedMessage(topic: topic, payload: payload));
  }

  @override
  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    subscribedTopics.add(topic);
  }

  void emitPayload(String payload) => _payloadController.add(payload);

  void emitError(Object error) => _payloadController.addError(error);
}

class PublishedMessage {
  PublishedMessage({required this.topic, required this.payload});

  final String topic;
  final String payload;
}

void main() {
  MQTTService createService(
    FakeMqttClientAdapter fakeClient, {
    Duration scanInterval = const Duration(hours: 1),
  }) {
    var nowMs = 1;

    return MQTTService(
      config: MQTTConfig(
        server: 'localhost',
        username: 'user',
        password: 'pass',
        scanInterval: scanInterval,
      ),
      clientFactory: (_, __) => fakeClient,
      clock: () => DateTime.fromMillisecondsSinceEpoch(nowMs++),
    );
  }

  test('initialize is idempotent for concurrent calls', () async {
    final fakeClient = FakeMqttClientAdapter();
    final service = createService(fakeClient);

    await Future.wait<void>(<Future<void>>[
      service.initialize(),
      service.initialize(),
    ]);

    expect(fakeClient.connectCalls, 1);
    expect(service.isInitialized, isTrue);
    expect(service.isConnected, isTrue);
    expect(fakeClient.subscribedTopics, <String>[
      'ble/scanner/${AppConstants.defaultDeviceId}/results',
    ]);

    service.dispose();
  });

  test('parseScanResultPayload parses valid payload', () {
    final fakeClient = FakeMqttClientAdapter();
    final service = createService(fakeClient);

    final payload = jsonEncode(<String, Object>{
      'scannerId': 'scanner_1',
      'devices': <Map<String, Object>>[
        <String, Object>{'id': 'dev1', 'name': 'Tag', 'rssi': -48},
      ],
    });

    final result = service.parseScanResultPayload(payload);

    expect(result.deviceId, 'scanner_1');
    expect(result.devices.single.rssi, -48);
  });

  test('invalid payload is emitted as stream error', () async {
    final fakeClient = FakeMqttClientAdapter();
    final service = createService(fakeClient);
    await service.initialize();

    final errorFuture = expectLater(
      service.scanResultStream,
      emitsError(isA<MQTTException>()),
    );

    fakeClient.emitPayload('not-json');
    await errorFuture;

    service.dispose();
  });

  test('scan loop publishes scan requests', () async {
    final fakeClient = FakeMqttClientAdapter();
    final service = createService(
      fakeClient,
      scanInterval: const Duration(milliseconds: 10),
    );

    await service.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 35));

    expect(fakeClient.publishedMessages, isNotEmpty);
    expect(
      fakeClient.publishedMessages.first.topic,
      'ble/scanner/${AppConstants.defaultDeviceId}/commands',
    );

    service.dispose();
  });

  test('initialize failure resets state and throws MQTTException', () async {
    final fakeClient = FakeMqttClientAdapter()..throwOnConnect = true;
    final service = createService(fakeClient);

    expect(service.initialize, throwsA(isA<MQTTException>()));
    await Future<void>.delayed(Duration.zero);

    expect(service.isInitialized, isFalse);
    expect(service.isConnected, isFalse);
  });

  test('dispose is idempotent', () async {
    final fakeClient = FakeMqttClientAdapter();
    final service = createService(fakeClient);

    await service.initialize();

    for (var i = 0; i < 2; i++) {
      service.dispose();
    }

    expect(fakeClient.disconnectCalls, 1);
  });
}
