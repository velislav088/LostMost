import 'package:flutter/material.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // get mqtt service
  final MQTTService _rssiService = MQTTService();
  String? _rssi;

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
  }

  Future<void> _initializeMQTT() async {
    await _rssiService.initialize();
    _rssiService.rssiStream.listen((value) {
      setState(() {
        _rssi = value;
      });
    });
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

  @override
  Widget build(BuildContext context) {
    final rssiValue = _rssi != null ? int.tryParse(_rssi!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context, 'home_title'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _rssi ?? AppLocalizations.of(context, 'connecting'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
