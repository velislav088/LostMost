import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/device.dart';
import 'package:mobile/models/scan_result.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/view_models/home_view_model.dart';
import 'package:mocktail/mocktail.dart';

class MockMQTTService extends Mock implements MQTTService {}

void main() {
  late MockMQTTService mockMqttService;
  late StreamController<ScanResult> streamController;
  late HomeViewModel viewModel;
  var disposedInTest = false;

  setUp(() {
    mockMqttService = MockMQTTService();
    streamController = StreamController<ScanResult>.broadcast();

    when(() => mockMqttService.initialize()).thenAnswer((_) async {});
    when(
      () => mockMqttService.scanResultStream,
    ).thenAnswer((_) => streamController.stream);

    viewModel = HomeViewModel(mqttService: mockMqttService);
  });

  tearDown(() async {
    if (!disposedInTest) {
      viewModel.dispose();
    }
    disposedInTest = false;
    await streamController.close();
  });

  test('initialize subscribes and updates RSSI', () async {
    await viewModel.initialize();

    streamController.add(
      ScanResult(
        deviceId: 'scanner_1',
        timestamp: DateTime.now(),
        devices: <Device>[Device(id: 'dev1', name: 'Tag', rssi: -55)],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.latestRssi, -55);
    expect(viewModel.currentRssi, 'RSSI: -55');
    expect(viewModel.error, isNull);
  });

  test('initialize captures stream errors', () async {
    await viewModel.initialize();

    streamController.addError('MQTT failed');
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.error, 'MQTT failed');
  });

  test('concurrent initialize calls only initialize mqtt once', () async {
    final completer = Completer<void>();
    when(
      () => mockMqttService.initialize(),
    ).thenAnswer((_) => completer.future);

    final firstCall = viewModel.initialize();
    final secondCall = viewModel.initialize();

    await Future<void>.delayed(Duration.zero);
    verify(() => mockMqttService.initialize()).called(1);
    completer.complete();
    await Future.wait<void>(<Future<void>>[firstCall, secondCall]);
  });

  test('dispose cancels subscription', () async {
    await viewModel.initialize();
    viewModel.dispose();
    disposedInTest = true;

    streamController.add(
      ScanResult(
        deviceId: 'scanner_1',
        timestamp: DateTime.now(),
        devices: <Device>[Device(id: 'dev1', name: 'Tag', rssi: -40)],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.latestScan, isNull);
  });
}
