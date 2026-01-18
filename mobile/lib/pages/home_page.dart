import 'package:flutter/material.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // get mqtt service
  late final MQTTService _rssiService;
  String? _rssi;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rssiService = Provider.of<MQTTService>(context, listen: false);
    _initializeMQTT();
  }

  Future<void> _initializeMQTT() async {
    try {
      await _rssiService.initialize();
      _rssiService.rssiStream.listen(
        (value) {
          if (mounted) {
            setState(() {
              _rssi = value;
              _error = null;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _rssiService.dispose();
    super.dispose();
  }

  String _getProximityLabel(BuildContext context, int rssi) {
    if (rssi >= -60) {
      return AppLocalizations.of(context, 'proximity_close');
    } else if (rssi >= -80) {
      return AppLocalizations.of(context, 'proximity_nearby');
    } else {
      return AppLocalizations.of(context, 'proximity_far');
    }
  }

  Color _getProximityColor(BuildContext context, int rssi) {
    if (rssi >= -60) {
      return context.success;
    } else if (rssi >= -80) {
      return context.warning;
    } else {
      return context.danger;
    }
  }

  // Parse RSSI output like integer
  int? _parseRssi(String s) {
    final match = RegExp(r'-?\d+').firstMatch(s);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0)!);
  }

  @override
  Widget build(BuildContext context) {
    final rssiValue = _rssi != null ? _parseRssi(_rssi!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context, 'home_title'))),
      body: Center(
        child: _error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: context.danger),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context, 'error'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.danger,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: context.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _rssi = null;
                      });
                      _initializeMQTT();
                    },
                    child: Text(AppLocalizations.of(context, 'retry')),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _rssi ?? AppLocalizations.of(context, 'connecting'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (rssiValue != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _getProximityLabel(context, rssiValue),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _getProximityColor(context, rssiValue),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
