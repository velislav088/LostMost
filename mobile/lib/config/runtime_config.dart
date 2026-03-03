import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RuntimeConfigException implements Exception {
  RuntimeConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RuntimeConfig {
  const RuntimeConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.mqttServer,
    required this.mqttUsername,
    required this.mqttPassword,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String mqttServer;
  final String mqttUsername;
  final String mqttPassword;

  static Future<RuntimeConfig> load() async {
    const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKeyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    const mqttServerDefine = String.fromEnvironment('MQTT_SERVER');
    const mqttUsernameDefine = String.fromEnvironment('MQTT_USERNAME');
    const mqttPasswordDefine = String.fromEnvironment('MQTT_PASSWORD');

    var dotEnvValues = const <String, String>{};

    if (kDebugMode) {
      try {
        await dotenv.load(fileName: 'assets/.env');
        dotEnvValues = dotenv.env;
      } catch (_) {
        dotEnvValues = const <String, String>{};
      }
    }

    String? resolveValue(String defineValue, String envKey) {
      if (defineValue.trim().isNotEmpty) {
        return defineValue.trim();
      }

      final envValue = dotEnvValues[envKey];
      if (envValue != null && envValue.trim().isNotEmpty) {
        return envValue.trim();
      }

      return null;
    }

    final supabaseUrl = resolveValue(supabaseUrlDefine, 'SUPABASE_URL');
    final supabaseAnonKey = resolveValue(
      supabaseAnonKeyDefine,
      'SUPABASE_ANON_KEY',
    );
    final mqttServer = resolveValue(mqttServerDefine, 'MQTT_SERVER');
    final mqttUsername = resolveValue(mqttUsernameDefine, 'MQTT_USERNAME');
    final mqttPassword = resolveValue(mqttPasswordDefine, 'MQTT_PASSWORD');

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw RuntimeConfigException(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY.',
      );
    }

    if (mqttServer == null || mqttUsername == null || mqttPassword == null) {
      throw RuntimeConfigException(
        'Missing MQTT_SERVER, MQTT_USERNAME, or MQTT_PASSWORD.',
      );
    }

    return RuntimeConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      mqttServer: mqttServer,
      mqttUsername: mqttUsername,
      mqttPassword: mqttPassword,
    );
  }
}
