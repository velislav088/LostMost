import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mobile/config/app_constants.dart';
import 'package:mobile/models/scan_result.dart';
import 'package:mobile/mqtt/mqtt_client_adapter.dart';

class MQTTException implements Exception {
  MQTTException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MQTTConfig {
  const MQTTConfig({
    required this.server,
    required this.username,
    required this.password,
    this.port = AppConstants.mqttPort,
    this.keepAliveSeconds = AppConstants.mqttKeepAlive,
    this.deviceId = AppConstants.defaultDeviceId,
    this.scanInterval = AppConstants.scanInterval,
  });

  final String server;
  final String username;
  final String password;
  final int port;
  final int keepAliveSeconds;
  final String deviceId;
  final Duration scanInterval;
}

typedef MQTTClientAdapterFactory =
    MQTTClientAdapter Function(MQTTConfig config, String clientIdentifier);

class MQTTService {
  MQTTService({
    required MQTTConfig config,
    MQTTClientAdapterFactory? clientFactory,
    DateTime Function()? clock,
  }) : _config = config,
       _clientFactory =
           clientFactory ??
           ((currentConfig, clientIdentifier) => MqttServerClientAdapter(
             config: currentConfig,
             clientIdentifier: clientIdentifier,
           )),
       _clock = clock ?? DateTime.now;

  final MQTTConfig _config;
  final MQTTClientAdapterFactory _clientFactory;
  final DateTime Function() _clock;

  final StreamController<ScanResult> _scanResultController =
      StreamController<ScanResult>.broadcast();

  MQTTClientAdapter? _client;
  void Function()? _cancelPayloadSubscription;
  Timer? _scanTimer;
  Future<void>? _initializationTask;

  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isDisposed = false;

  Stream<ScanResult> get scanResultStream => _scanResultController.stream;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;

  Future<void> initialize() {
    if (_isDisposed) {
      return Future<void>.error(
        MQTTException('MQTT service has already been disposed.'),
      );
    }

    if (_isInitialized) {
      return Future<void>.value();
    }

    final pendingInitialization = _initializationTask;
    if (pendingInitialization != null) {
      return pendingInitialization;
    }

    final initialization = _initializeInternal().whenComplete(() {
      _initializationTask = null;
    });
    _initializationTask = initialization;
    return initialization;
  }

  Future<void> _initializeInternal() async {
    _resetConnectionState();

    final clientIdentifier =
        'flutter_client_${_clock().millisecondsSinceEpoch}';
    final client = _clientFactory(_config, clientIdentifier);
    _client = client;

    try {
      await client.connect();
      _isConnected = true;

      client.subscribe(_resultsTopic);

      final payloadSubscription = client.payloadMessages.listen(
        _handlePayloadMessage,
        onError: (Object error, StackTrace stackTrace) {
          _addStreamError(MQTTException('MQTT payload stream failure.'));
        },
      );
      _cancelPayloadSubscription = () {
        unawaited(payloadSubscription.cancel());
        _cancelPayloadSubscription = null;
      };

      _scanTimer = Timer.periodic(_config.scanInterval, (_) {
        _publishScanRequest();
      });

      _isInitialized = true;
    } catch (error) {
      _resetConnectionState();
      _safeDisconnect(client);
      _client = null;

      if (error is MQTTException) {
        rethrow;
      }

      throw MQTTException('Failed to initialize MQTT connection.');
    }
  }

  String get _resultsTopic => 'ble/scanner/${_config.deviceId}/results';
  String get _commandsTopic => 'ble/scanner/${_config.deviceId}/commands';

  @visibleForTesting
  ScanResult parseScanResultPayload(String payloadString) {
    final decoded = jsonDecode(payloadString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('MQTT payload must be a JSON object.');
    }

    return ScanResult.fromJson(decoded);
  }

  void _handlePayloadMessage(String payloadString) {
    try {
      final result = parseScanResultPayload(payloadString);
      if (_scanResultController.isClosed) {
        return;
      }
      _scanResultController.add(result);
    } catch (_) {
      _addStreamError(MQTTException('Failed to parse scan result payload.'));
    }
  }

  void _publishScanRequest() {
    if (!_isConnected) {
      return;
    }

    final client = _client;
    if (client == null) {
      return;
    }

    final requestId = 'flutter_${_clock().millisecondsSinceEpoch}';
    final scanMessage = jsonEncode(<String, String>{
      'action': 'scan',
      'requestId': requestId,
    });

    try {
      client.publishUtf8(_commandsTopic, scanMessage);
    } catch (_) {
      _addStreamError(MQTTException('Failed to send scan request.'));
    }
  }

  void _addStreamError(MQTTException error) {
    if (_scanResultController.isClosed) {
      return;
    }
    _scanResultController.addError(error);
  }

  void _resetConnectionState() {
    _scanTimer?.cancel();
    _scanTimer = null;

    _cancelPayloadSubscription?.call();
    _cancelPayloadSubscription = null;

    _isInitialized = false;
    _isConnected = false;
  }

  void _safeDisconnect(MQTTClientAdapter client) {
    try {
      client.disconnect();
    } catch (_) {}
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _scanTimer?.cancel();
    _scanTimer = null;

    _cancelPayloadSubscription?.call();
    _cancelPayloadSubscription = null;

    _isInitialized = false;
    _isConnected = false;

    final client = _client;
    _client = null;
    if (client != null) {
      _safeDisconnect(client);
    }

    if (!_scanResultController.isClosed) {
      _scanResultController.close();
    }
  }
}
